//
//  AbstractSyntaxTree.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation
import Cocoa

enum ParserError: Error {
	case unexpected(token: Token, at: TokenIndex)
	case alreadyReturned(at: TokenIndex)
	case invalidVariable(variable: Assignable, at: TokenIndex)
	case invalidCall(call: Assignable, at: TokenIndex)
	case expectedExpression(at: TokenIndex)
	case endOfStream
}

extension Collection where Indices.Iterator.Element == Index {
	
	/// Returns the element at the specified index iff it is within bounds, otherwise nil.
	/// Thanks to: http://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings
	subscript (safe index: Index) -> Generator.Element? {
		return indices.contains(index) ? self[index] : nil
	}
	
}

struct AbstractSyntaxTree {
	
	var tree: Block!
	private var iterator: LexerIterator
	private let lexer: Lexer
	
	init(lexer: Lexer) throws {
		iterator = lexer.makeIterator()
		self.lexer = lexer
		self.tree = try block()
	}
	
	mutating func block(endDelimiter: Bool = true, elseDelimiter: Bool = false, untilDelimiter: Bool = false) throws -> Block {
		var statements = [Statement]()
		var hasReturned = false
		while let statement = try statement(hasReturned: hasReturned, endDelimiter: endDelimiter, elseDelimiter: elseDelimiter, untilDelimiter: untilDelimiter) {
			statements.append(statement)
			switch statement {
			case .return(_, _):
				hasReturned = true // there should either by no more statements or a delimiter after this
			default: break
			}
		}
		return statements
	}
	
	mutating func statement(hasReturned: Bool = false, endDelimiter: Bool = false, elseDelimiter: Bool = false, untilDelimiter: Bool = false) throws -> Statement? {
		while let (index, token) = iterator.next() {
			token: switch token {
			case .keyword(let keyword):
				if hasReturned { // prevent any statements after a return, other than a delimiter
					switch keyword {
					case .end:
						if !endDelimiter { fallthrough }
					case .else, .elseif:
						if !elseDelimiter { fallthrough }
					case .until:
						if !untilDelimiter { fallthrough }
					default:
						throw ParserError.alreadyReturned(at: index)
					}
				}
				
				switch keyword {
				case .do:
					return Statement.do(block: try block(), at: index)
				case .while:
					return Statement.while(condition: try expression(), block: try block(), at: index)
				case .repeat:
					return Statement.repeat(block: try block(endDelimiter: false, untilDelimiter: true), condition: try expression(), at: index)
				case .if:
					return try ifStatement(at: index)
				case .for:
					return try forStatement(at: index)
				case .break:
					return Statement.break(at: index)
				case .goto:
//					TODO: consider checking for Lua >= 5.2
					return Statement.goto(label: try identifier(), at: index)
				case .local:
					return try local(at: index)
				case .function:
					// get the function name
					var names = [Identifier]()
					var isMethod = false
					while true {
						names.append(try identifier())
						if isMethod {
							break // there shouldn't be any more names after :
						}
						else if consume(operator: .dot) {}
						else if consume(operator: .colon) {
							isMethod = true
						}
						else {
							break // no dot or colon, those are all the names
						}
					}
					return .function(names: names, isMethod: isMethod, function: try functionBody(at: iterator.index), at: index)
				case .end:
					if endDelimiter {
						return nil
					}
				case .else, .elseif:
					if elseDelimiter {
						return nil
					}
					fallthrough //throw ParserError.unexpected(token: token)
				case .until:
					if untilDelimiter {
						return nil
					}
					fallthrough //throw ParserError.unexpected(token: token)
				case .repeat:
					return Statement.return(try expressionList(), at: index)
				default:
					throw ParserError.unexpected(token: token, at: index)
				}
			case .operator(let op):
				switch op {
				case .doubleColon:
//					TODO: consider checking for Lua >= 5.2
					return try label(at: index)
				case .semicolon:
					break
				case .roundBracketLeft:
					// we're part of a prefix expression
					iterator.undo()
					return try assignmentOrFunctionCall(at: index)
				default:
					throw ParserError.unexpected(token: token, at: index)
				}
			case .identifier(_):
				iterator.undo()
				// we're part of a prefix expression
				return try assignmentOrFunctionCall(at: index)
			default:
				throw ParserError.unexpected(token: token, at: index)
			}
		}
		return nil
	}
	
	func validate(variable: Assignable, at index: String.Index) throws {
		if !(variable is ExpressionIndex || variable is IdentifierIndex || variable is Identifier) {
			throw ParserError.invalidVariable(variable: variable, at: index) // TODO: we probably need location information here
		}
	}
	
	func validate(call: Assignable, at index: String.Index) throws {
		if !(call is Callable) {
			throw ParserError.invalidCall(call: call, at: index)
		}
	}
	
	mutating func assignmentOrFunctionCall(at index: String.Index) throws -> Statement {
		let prefix = try prefixExpression()
		
		switch prefix {
		case .prefix(let assignable, at: let index):
			// this could be a variable list or function call
			if let (lookAheadIndex, lookAheadToken) = iterator.lookAhead {
				switch lookAheadToken {
				case .operator(let op):
					switch op {
					case .comma, .equal:
						// we are a variable assignment
						try validate(variable: assignable, at: lookAheadIndex)
						var assignables: [Assignable] = [assignable]

						// get any subsequent variables
						while consume(operator: .comma) {
							switch try prefixExpression() {
							case .prefix(let assignable, _):
								try validate(variable: assignable, at: iterator.index)
								assignables.append(assignable)
							default: break
							}
						}
						
						try expect(operator: .equal)
						
						// get the expressions for assignment
						var expressions = [Expression]()
						repeat {
							expressions.append(try expression())
						}
						while consume(operator: .comma)
						
						return Statement.assignment(assignables: assignables, expressions: expressions, at: index)
					default: break // we are a function call (or invalid)
					}
				default: break // we are a function call (or invalid)
				}
				
				// should be a function call, validate first
				try validate(call: assignable, at: index)
				return Statement.call(assignable as! Callable, at: index)
			}
			else {
				// invalid, there should be a token here
				throw ParserError.endOfStream
			}
		default:
			throw ParserError.endOfStream // TODO: don't think this should ever happen, maybe handle it differently
		}
	}
	
	mutating func expect(operator target: Operator) throws {
		if let (index, token) = iterator.next() {
			switch token {
			case .operator(let op):
				switch op {
				case target: return
				default: break
				}
			default: break
			}
			throw ParserError.unexpected(token: token, at: index)
		}
		throw ParserError.endOfStream
	}
	
	mutating func consume(operator target: Operator) -> Bool {
		if let (_, token) = iterator.lookAhead {
			switch token {
			case .operator(let op):
				switch op {
				case target:
					// found what we're looking for, jump over it
					iterator.skip()
					return true
				default: break
				}
			default: break
			}
		}
		return false
	}

	mutating func prefixExpression() throws -> Expression {
		var node: Assignable
		let expressionIndex: TokenIndex
		if let (index, token) = iterator.lookAhead {
			expressionIndex = index
			token: switch token {
			case .identifier(_):
				node = try identifier()
			case .operator(let op):
				switch op {
				case .roundBracketLeft:
					node = Expression.brackets(try expression(), at: index)
					try expect(operator: .roundBracketRight)
					break token
				default: break
				}
				fallthrough
			default:
				throw ParserError.unexpected(token: token, at: index) // TODO: in these situations does _ == index?
			}
		}
		else {
			throw ParserError.endOfStream
		}
		
		loop: while true {
			if let (tokenIndex, token) = iterator.next() {
				token: switch token {
				case .operator(let op):
					switch op {
					case .squareBracketLeft:
						// an expression index (i.e. one[two])
						node = ExpressionIndex(indexed: node, index: try expression())
						try expect(operator: .squareBracketRight)
					case .dot:
						// an identifier index (i.e. one.two)
						node = IdentifierIndex(indexed: node, index: try identifier())
					case .colon:
						// this is a invocation call
						node = Invocation(callee: node, method: try identifier(), arguments: try arguments(at: tokenIndex))
					case .roundBracketLeft, .curlyBracketLeft:
						iterator.undo() // this bracket needs to be dealt with in arguments()
						node = Call(callee: node, arguments: try arguments(at: tokenIndex))
					default:
						// there are no more tokens that add meaning to this prefix expression, return it
						iterator.undo()
						break loop
					}
				case .string(let string):
					// a string call (i.e. print "Hello world!")
					node = Call(callee: node, arguments: [.string(string, at: tokenIndex)])
				default:
					// there are no more tokens that add meaning to this prefix expression, return it
					iterator.undo()
					break loop
				}
			}
			else {
				// TODO: this should probably just return the prefix, but what about
				throw ParserError.endOfStream
			}
		}
		
		return Expression.prefix(node, at: expressionIndex)
	}
	
	mutating func arguments(at index: String.Index) throws -> [Expression] {
		if consume(operator: .roundBracketLeft) {
			// brackets with a list of expressions (i.e. standard calling
			let expressions = try expressionList()
			try expect(operator: .roundBracketRight)
			return expressions
		}
		else if consume(operator: .curlyBracketLeft) {
			return [try table(at: index)]
		}
		else if let (index, token) = iterator.next() {
			switch token {
			case .string(let string):
				return [.string(string, at: index)]
			default: break
			}
			throw ParserError.unexpected(token: token, at: index)
		}
		throw ParserError.endOfStream
	}
	
	mutating func label(at index: String.Index) throws -> Statement {
		let label = Statement.label(label: try identifier(), at: index)
		if let (tokenIndex, token) = iterator.next() {
			switch token {
			case .operator(let op):
				switch op {
				case .doubleColon:
					return label
				default: break
				}
				fallthrough
			default:
				throw ParserError.unexpected(token: token, at: tokenIndex)
			}
		}
		throw ParserError.endOfStream
	}
	
	mutating func identifier() throws -> Identifier {
		if let (index, token) = iterator.next() {
			switch token {
			case .identifier(let identifier):
				return identifier
			default:
				throw ParserError.unexpected(token: token, at: index)
			}
		}
		throw ParserError.endOfStream
	}
	
	mutating func identifier() -> Identifier? {
		if let (_, token) = iterator.lookAhead {
			switch token {
			case .identifier(let identifier):
				iterator.skip()
				return identifier
			default: break
			}
		}
		return nil
	}
	
	mutating func table(at index: TokenIndex) throws -> Expression {
		// this assumes the first { has already been consumed
		var fields = [TableItem]()
		
		while true {
			var key: FieldIndex?
			
			if consume(operator: .squareBracketLeft) {
				// expression key (i.e. [key] = ...)
				key = try expression() as Expression
				try expect(operator: .squareBracketRight)
				try expect(operator: .equal)
			}
			else if let ident = identifier() as Identifier? {
				// identifier key (i.e. key = ...)
				if consume(operator: .equal) {
					key = ident
				}
				else {
					// as there is not an equals operator this is not the key, just the value
					iterator.undo()
				}
			}
			
			// now get the value. if we have a key we are expecting an expression, otherwise we just break the loop
			if let value = try expression() as Expression? {
				fields.append((key, value))
				if !consume(operator: .comma) {
					// if there wasn't a trailing comma break
					break
				}
			}
			else if key != nil {
				throw ParserError.expectedExpression(at: iterator.index) // as there was a key we are expecting an expression
			}
			else {
				// there wasn't a key or a value
				break
			}
		}
		try expect(operator: .curlyBracketRight) // consume the closing bracket
		return .table(fields, at: index)
	}
	
	mutating func functionBody(at index: TokenIndex) throws -> Expression {
		try expect(operator: .roundBracketLeft)
		var wasComma = false
		var names = [Identifier]()
		while let name = identifier() as Identifier? {
			names.append(name)
			wasComma = consume(operator: .comma)
			if wasComma {
				break
			}
		}
		
		var isVarArg = false
		if wasComma {
			// it there's a trailing comma but no identifier then ... MUST be next
			isVarArg = true
			try expect(operator: .varArg)
		}
		else if names.count == 0 {
			isVarArg = consume(operator: .varArg)
		}
		try expect(operator: .roundBracketRight)
		return .function(names, try block(), isVarArg: isVarArg, at: index)
	}
	
	mutating func primaryExpression(_ token: Token, at index: TokenIndex) throws -> Expression? {
		token: switch token {
		case .string(let string):
			return .string(string, at: index)
		case .number(let number):
			return .number(number, at: index)
		case .operator(let op):
			switch op {
			case .varArg: // ...
				return .varArg(at: index)
			case .curlyBracketLeft: // table
				return try table(at: index)
			default: break
			}
		case .keyword(let keyword):
			switch keyword {
			case .true:
				return .bool(true, at: index)
			case .false:
				return .bool(false, at: index)
			case .nil:
				return .nil(at: index)
			case .function:
				return try functionBody(at: index)
			default: break
			}
		default: break
		}
		return nil
	}
	
	mutating func expression(minPrecedence: Precedence? = nil) throws -> Expression? {
		var exp: Expression!
		if let (tokenIndex, token) = iterator.next() {
			// try unary expressions first
			if let nodeOperator = NodeOperator.from(token: token), nodeOperator.isUnary {
				exp = .operator(nodeOperator, try expression(minPrecedence: Precedence.multiplicationDivision), nil, at: tokenIndex)
			}
			else {
				// if it wasn't unary try a primary expression
				exp = try primaryExpression(token, at: tokenIndex)
				if exp == nil {
					// wasn't a primary expression, must be a prefixExpression
					iterator.undo()
					exp = try prefixExpression()
					if exp == nil {
						return nil
					}
				}
			}
		}
		else {
			return nil
		}
		
		// we have the expression, now work out precedence of operators an following expressions
		while let (index, token) = iterator.lookAhead, let nodeOperator = NodeOperator.from(token: token) {
			let precedence = nodeOperator.precedence()
			if precedence == nil || (minPrecedence != nil && precedence! <= minPrecedence!) {
				break
			}
			iterator.skip()
			
			let subExpression: Expression = try expression(minPrecedence: precedence!)
			exp = .operator(nodeOperator, exp, subExpression, at: index)
		}
		return exp
	}
	
	mutating func expression(minPrecedence: Precedence? = nil) throws -> Expression {
		if let exp = try expression(minPrecedence: minPrecedence) as Expression? {
			return exp
		}
		else {
			throw ParserError.expectedExpression(at: iterator.index)
		}
	}
	
	mutating func expressionList() throws -> [Expression] {
		var expressions = [Expression]()
		while true {
			if let exp = try expression() as Expression? {
				expressions.append(exp)
				if !consume(operator: .comma) {
					break // no trailing comma, the list has ended
				}
			}
		}
		return expressions
	}
	
	mutating func local(at index: String.Index) throws -> Statement {
		// we need to determine whether this is a local function declaration or variable
		var isFunction: Bool?
		var variables = [Identifier]()
		var expectComma = false
		while let (tokenIndex, token) = iterator.next() {
			token: switch token {
			case .identifier(let identifier):
				// local variable. there might be a comma with more variables this though
				if isFunction != nil && isFunction! { // this local is a function, we will use this as the name
					return .localFunction(name: identifier, function: try functionBody(at: tokenIndex), at: index)
				}
				else if expectComma == false {
					variables.append(identifier)
					expectComma = true
					isFunction = false
					break
				}
				throw ParserError.unexpected(token: token, at: tokenIndex)
			case .operator(let op):
				if expectComma { // this only applies if we're not a function
					switch op {
					case .comma:
						expectComma = false // we have the comma, we can now expect another variable
						break token
					case .equal:
						let values = try expressionList()
						if values.count == 0 {
							throw ParserError.expectedExpression(at: iterator.index)
						}
						return .local(variables: variables, values: values, at: index)
					default:
						// this token isn't actually part of the local declaration. we need to unconsume it
						iterator.undo()
						return .local(variables: variables, values: [], at: index)
					}
				}
				throw ParserError.unexpected(token: token, at: tokenIndex)
			case .keyword(let keyword):
				if expectComma {
					// this token isn't actually part of the local declaration. we need to unconsume it
					iterator.undo()
					return .local(variables: variables, values: [], at: index)
				}
				switch keyword {
				case .function:
					if isFunction == nil {
						isFunction = true
						break
					}
					fallthrough
				default:
					throw ParserError.unexpected(token: token, at: tokenIndex)
				}
			default:
				if expectComma {
					// this token isn't actually part of the local declaration. we need to unconsume it
					iterator.undo()
					return .local(variables: variables, values: [], at: index)
				}
				throw ParserError.unexpected(token: token, at: tokenIndex)
			}
		}
		
		if expectComma {
			// the declaration is actually complete, we can return
			return .local(variables: variables, values: [], at: index)
		}
		throw ParserError.endOfStream
	}
	
	mutating func ifStatement(at index: String.Index) throws -> Statement {
		var conditionals = [(Expression, Block)]()
		var elseBlock: Block?
		eachCondition: while true {
			conditionals.append((try expression(), try block(elseDelimiter: true)))
			//	we need to check whether the ending keyword of the block was else or end, elseif will just loop again
			switch iterator.lastToken!.1 {
			case .keyword(let keyword):
				switch keyword {
				case .else:
					elseBlock = try block()
				case .end:
					break eachCondition
				default: break
				}
			default: break
			}
		}
		return Statement.if(conditionals: conditionals, else: elseBlock, at: index)
	}
	
	mutating func forStatement(at index: String.Index) throws -> Statement {
		// at this stage we've no idea whether the for loop is a 'for a in b` or `for i = a, b`
		var variables = [Identifier]()
		var isNumerical: Bool?
		var expectComma = false
		variables: while true {
			if let (index, token) = iterator.next() {
				token: switch token {
				case .identifier(let identifier):
					if isNumerical != nil, isNumerical! {
						throw ParserError.unexpected(token: token, at: index)
					} // numerical loops shouldn't have more than one variable
					variables.append(identifier)
					expectComma = true
				case .operator(let op):
					switch op {
					case .comma:
						if expectComma {
							expectComma = false // we have the comma, we can now expect another variable
							isNumerical = false // we now also know that this is not a numerical loop
							break token
						}
						//							this comma shouldn't be here
						break
					case .equal:
						if expectComma && (isNumerical == nil || isNumerical!) {
							isNumerical = true
							break variables // we've reached the end of the list of variables
						}
					break // this equal shouldn't be here
					default: break
					}
					throw ParserError.unexpected(token: token, at: index)
				case .keyword(let keyword):
					switch keyword {
					case .in:
						if expectComma && (isNumerical == nil || !isNumerical!) {
							isNumerical = false
							break variables // we've reached the end of the list of variables
						}
					break  // this `in` shouldn't be here
					default: break
					}
					fallthrough
				default:
					throw ParserError.unexpected(token: token, at: index)
				}
			}
			else {
				throw ParserError.endOfStream
			}
		}
		
		//		we have all of the variables now
		//		now we need 2 - 3 expressions for numerical or 1+ expressions for non-numerical
		var iterators = [Expression]()
		iterators: while true {
			iterators.append(try expression())
			if let (index, token) = iterator.next() {
				token: switch token {
				case .operator(let op):
					switch op {
					case .comma:
						if isNumerical! && iterators.count >= 3 {
							throw ParserError.unexpected(token: token, at: index) // we already have three expressions, we can't have a fourth. error
						}
						continue
					default:
						throw ParserError.unexpected(token: token, at: index)
					}
				case .keyword(let keyword):
					switch keyword {
					case .do:
						if isNumerical! && iterators.count < 2 {
							throw ParserError.unexpected(token: token, at: index) // we don't have at least two expressions. error.
						}
						break iterators // we have reached the `do`, get out and read the block
					default:
						throw ParserError.unexpected(token: token, at: index)
					}
				default:
					throw ParserError.unexpected(token: token, at: index)
				}
			}
		}
		
		if isNumerical! {
			return Statement.forNumerical(variable: variables[0], start: iterators[0], stop: iterators[1], increment: iterators[safe: 2], block: try block(), at: index)
		}
		else {
			return Statement.forIn(variables: variables, iterators: iterators, block: try block(), at: index)
		}
	}
	
}























