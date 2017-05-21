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
	case unexpected(token: Token)
	case alreadyReturned
	case invalidVariable(variable: Assignable)
	case invalidCall(call: Assignable)
	case expectedExpression
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
	
	let tree = [Node]()
	private var iterator: LexerIterator
	private let lexer: Lexer
	
	init(lexer: Lexer) throws {
		iterator = lexer.makeIterator()
		self.lexer = lexer
		try block()
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
						throw ParserError.alreadyReturned
					}
				}
				
				switch keyword {
				case .do:
					return Statement.do(block: try block(), lexer.position(of: index)!)
				case .while:
					return Statement.while(condition: try expression(), block: try block(), lexer.position(of: index)!)
				case .repeat:
					return Statement.repeat(block: try block(endDelimiter: false, untilDelimiter: true), condition: try expression(), lexer.position(of: index)!)
				case .if:
					return try ifStatement(index)
				case .for:
					return try forStatement(index)
				case .break:
					return Statement.break(lexer.position(of: index)!)
				case .goto:
//					TODO: consider checking for Lua >= 5.2
					return Statement.goto(label: try identifier(), lexer.position(of: index)!)
				case .local:
					return try local(index)
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
					return .function(names: names, isMethod: isMethod, function: try functionBody(), lexer.position(of: index)!)
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
					return Statement.return(try expressionList(), lexer.position(of: index)!)
				default:
					throw ParserError.unexpected(token: token)
				}
			case .operator(let op):
				switch op {
				case .doubleColon:
//					TODO: consider checking for Lua >= 5.2
					return try label(index)
				case .semicolon:
					break
				case .roundBracketLeft:
					// we're part of a prefix expression
					iterator.undo()
					return try assignmentOrFunctionCall(index)
				default:
					throw ParserError.unexpected(token: token)
				}
			case .identifier(_):
				iterator.undo()
				// we're part of a prefix expression
				return try assignmentOrFunctionCall(index)
			default:
				throw ParserError.unexpected(token: token)
			}
		}
		return nil
	}
	
	func validate(variable: Assignable) throws {
		if !(variable is ExpressionIndex || variable is IdentifierIndex || variable is Identifier) {
			throw ParserError.invalidVariable(variable: variable) // TODO: we probably need location information here
		}
	}
	
	func validate(call: Assignable) throws {
		if !(call is Callable) {
			throw ParserError.invalidCall(call: call)
		}
	}
	
	mutating func assignmentOrFunctionCall(_ index: String.Index) throws -> Statement {
		let prefix = try prefixExpression(index)
		
		switch prefix {
		case .prefix(let assignable, _):
			// this could be a variable list or function call
			if let (_, lookAheadToken) = iterator.lookAhead {
				switch lookAheadToken {
				case .operator(let op):
					switch op {
					case .comma, .equal:
						// we are a variable assignment
						try validate(variable: assignable)
						var assignables: [Assignable] = [assignable]

						// get any subsequent variables
						while consume(operator: .comma) {
							switch try prefixExpression(iterator.index) {
							case .prefix(let assignable, _):
								try validate(variable: assignable)
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
						
						return Statement.assignment(assignables: assignables, expressions: expressions, lexer.position(of: index)!)
					default: break // we are a function call (or invalid)
					}
				default: break // we are a function call (or invalid)
				}
				
				// should be a function call, validate first
				try validate(call: assignable)
				return Statement.call(assignable as! Callable, lexer.position(of: index)!)
			}
			else {
				// invalid, there should be a token here
				throw ParserError.endOfStream
			}
		default:break
		}
		throw ParserError.endOfStream // TODO: don't think this should ever happen, maybe handle it differently
	}
	
	mutating func expect(operator target: Operator) throws {
		if let (_, token) = iterator.next() {
			switch token {
			case .operator(let op):
				switch op {
				case target: return
				default: break
				}
			default: break
			}
			throw ParserError.unexpected(token: token)
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

	mutating func prefixExpression(_ index: String.Index) throws -> Expression {
		var node: Assignable
		if let (_, token) = iterator.lookAhead {
			token: switch token {
			case .identifier(_):
				node = try identifier()
			case .operator(let op):
				switch op {
				case .roundBracketLeft:
					node = Expression.brackets(try expression(), lexer.position(of: index)!)
					try expect(operator: .roundBracketRight)
					break token
				default: break
				}
				fallthrough
			default:
				throw ParserError.unexpected(token: token)
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
						node = Invocation(callee: node, method: try identifier(), arguments: try arguments(tokenIndex))
					case .roundBracketLeft, .curlyBracketLeft:
						iterator.undo() // this bracket needs to be dealt with in arguments()
						node = Call(callee: node, arguments: try arguments(tokenIndex))
					default:
						// there are no more tokens that add meaning to this prefix expression, return it
						iterator.undo()
						break loop
					}
				case .string(let string):
					// a string call (i.e. print "Hello world!")
					node = Call(callee: node, arguments: [.string(string)])
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
		
		return Expression.prefix(node, lexer.position(of: index)!)
	}
	
	mutating func arguments(_ index: String.Index) throws -> [Expression] {
		if consume(operator: .roundBracketLeft) {
			// brackets with a list of expressions (i.e. standard calling
			let expressions = try expressionList()
			try expect(operator: .roundBracketRight)
			return expressions
		}
		else if consume(operator: .curlyBracketLeft) {
			return [try table()]
		}
		else if let (_, token) = iterator.next() {
			switch token {
			case .string(let string):
				return [.string(string)]
			default: break
			}
			throw ParserError.unexpected(token: token)
		}
		throw ParserError.endOfStream
	}
	
	mutating func label(_ index: String.Index) throws -> Statement {
		let label = Statement.label(label: try identifier(), lexer.position(of: index)!)
		if let (_, token) = iterator.next() {
			switch token {
			case .operator(let op):
				switch op {
				case .doubleColon:
					return label
				default: break
				}
				fallthrough
			default:
				throw ParserError.unexpected(token: token)
			}
		}
		throw ParserError.endOfStream
	}
	
	mutating func identifier() throws -> Identifier {
		if let (_, token) = iterator.next() {
			switch token {
			case .identifier(let identifier):
				return identifier
			default:
				throw ParserError.unexpected(token: token)
			}
		}
		throw ParserError.endOfStream
	}
	
	mutating func identifier() throws -> Identifier? {
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
	
	mutating func table() throws -> Expression {
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
			else if let ident: Identifier = try identifier() {
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
				throw ParserError.expectedExpression // as there was a key we are expecting an expression
			}
			else {
				// there wasn't a key or a value
				break
			}
		}
		try expect(operator: .curlyBracketRight) // consume the closing bracket
		return .table(fields)
	}
	
	mutating func functionBody() throws -> Expression {
		try expect(operator: .roundBracketLeft)
		var wasComma = false
		var names = [Identifier]()
		while let name = try identifier() as Identifier? {
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
		return .function(names, try block(), isVarArg: isVarArg)
	}
	
	mutating func primaryExpression(_ token: Token) throws -> Expression? {
		token: switch token {
		case .string(let string):
			return .string(string)
		case .number(let number):
			return .number(number)
		case .operator(let op):
			switch op {
			case .varArg: // ...
				return .varArg
			case .curlyBracketLeft: // table
				return try table()
			default: break
			}
		case .keyword(let keyword):
			switch keyword {
			case .true:
				return .bool(true)
			case .false:
				return .bool(false)
			case .nil:
				return .nil
			case .function:
				return try functionBody()
			default: break
			}
		default: break
		}
		return nil
	}
	
	mutating func expression(minPrecedence: Precedence? = nil) throws -> Expression? {
		var exp: Expression!
		if let (index, token) = iterator.next() {
			// try unary expressions first
			if let nodeOperator = NodeOperator.from(token: token), nodeOperator.isUnary {
				exp = .operator(nodeOperator, try expression(minPrecedence: Precedence.multiplicationDivision), nil)
			}
			else {
				// if it wasn't unary try a primary expression
				exp = try primaryExpression(token)
				if exp == nil {
					// wasn't a primary expression, must be a prefixExpression
					iterator.undo()
					exp = try prefixExpression(index) // TODO: this index IS wrong
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
		while let (_, token) = iterator.lookAhead, let nodeOperator = NodeOperator.from(token: token) {
			let precedence = nodeOperator.precedence()
			if precedence == nil || (minPrecedence != nil && precedence! <= minPrecedence!) {
				break
			}
			iterator.skip()
			
			let subExpression: Expression = try expression(minPrecedence: precedence!)
			exp = .operator(nodeOperator, exp, subExpression)
		}
		return exp
	}
	
	mutating func expression(minPrecedence: Precedence? = nil) throws -> Expression {
		if let exp = try expression(minPrecedence: minPrecedence) as Expression? {
			return exp
		}
		else {
			throw ParserError.expectedExpression
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
	
	mutating func local(_ index: String.Index) throws -> Statement {
		// we need to determine whether this is a local function declaration or variable
		var isFunction: Bool?
		var variables = [Identifier]()
		var expectComma = false
		while let (_, token) = iterator.next() {
			token: switch token {
			case .identifier(let identifier):
				// local variable. there might be a comma with more variables this though
				if isFunction != nil && isFunction! { // this local is a function, we will use this as the name
					return .localFunction(name: identifier, function: try functionBody(), lexer.position(of: index)!)
				}
				else if expectComma == false {
					variables.append(identifier)
					expectComma = true
					isFunction = false
					break
				}
				throw ParserError.unexpected(token: token)
			case .operator(let op):
				if expectComma { // this only applies if we're not a function
					switch op {
					case .comma:
						expectComma = false // we have the comma, we can now expect another variable
						break token
					case .equal:
						let values = try expressionList()
						if values.count == 0 {
							throw ParserError.expectedExpression
						}
						return .local(variables: variables, values: values, lexer.position(of: index)!)
					default:
						// this token isn't actually part of the local declaration. we need to unconsume it
						iterator.undo()
						return .local(variables: variables, values: [], lexer.position(of: index)!)
					}
				}
				throw ParserError.unexpected(token: token)
			case .keyword(let keyword):
				if expectComma {
					// this token isn't actually part of the local declaration. we need to unconsume it
					iterator.undo()
					return .local(variables: variables, values: [], lexer.position(of: index)!)
				}
				switch keyword {
				case .function:
					if isFunction == nil {
						isFunction = true
						break
					}
					fallthrough
				default:
					throw ParserError.unexpected(token: token)
				}
			default:
				if expectComma {
					// this token isn't actually part of the local declaration. we need to unconsume it
					iterator.undo()
					return .local(variables: variables, values: [], lexer.position(of: index)!)
				}
				throw ParserError.unexpected(token: token)
			}
		}
		
		if expectComma {
			// the declaration is actually complete, we can return
			return .local(variables: variables, values: [], lexer.position(of: index)!)
		}
		throw ParserError.endOfStream
	}
	
	mutating func ifStatement(_ index: String.Index) throws -> Statement {
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
		return Statement.if(conditionals: conditionals, else: elseBlock, lexer.position(of: index)!)
	}
	
	mutating func forStatement(_ index: String.Index) throws -> Statement {
		// at this stage we've no idea whether the for loop is a 'for a in b` or `for i = a, b`
		var variables = [Identifier]()
		var isNumerical: Bool?
		var expectComma = false
		variables: while true {
			if let token = iterator.next() {
				token: switch token.1 {
				case .identifier(let identifier):
					if isNumerical != nil, isNumerical! {
						throw ParserError.unexpected(token: token.1)
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
					throw ParserError.unexpected(token: token.1)
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
					throw ParserError.unexpected(token: token.1)
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
			if let token = iterator.next() {
				token: switch token.1 {
				case .operator(let op):
					switch op {
					case .comma:
						if isNumerical! && iterators.count >= 3 {
							throw ParserError.unexpected(token: token.1) // we already have three expressions, we can't have a fourth. error
						}
						continue
					default:
						throw ParserError.unexpected(token: token.1)
					}
				case .keyword(let keyword):
					switch keyword {
					case .do:
						if isNumerical! && iterators.count < 2 {
							throw ParserError.unexpected(token: token.1) // we don't have at least two expressions. error.
						}
						break iterators // we have reached the `do`, get out and read the block
					default:
						throw ParserError.unexpected(token: token.1)
					}
				default:
					throw ParserError.unexpected(token: token.1)
				}
			}
		}
		
		if isNumerical! {
			return Statement.forNumerical(variable: variables[0], start: iterators[0], stop: iterators[1], increment: iterators[safe: 2], block: try block(), lexer.position(of: index)!)
		}
		else {
			return Statement.forIn(variables: variables, iterators: iterators, block: try block(), lexer.position(of: index)!)
		}
	}
	
}























