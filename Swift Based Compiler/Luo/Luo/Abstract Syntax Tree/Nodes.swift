//
//  AbstractSyntaxTreeNodes.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation


enum Node {
	
	case block(Block)
    case statement(Statement)
    case expression(Expression)
    case call(Callable)
    case identifier(Identifier)
    case assignee(Assignable)

}

typealias Block = [Statement]
typealias Label = String
indirect enum Statement {
	
	case `do`(block: Block, at: TokenIndex)
	case assignment(assignables: [Assignable], expressions: [Expression], at: TokenIndex)
	case `while`(condition: Expression, block: Block, at: TokenIndex)
	case `repeat`(block: Block, condition: Expression, at: TokenIndex)
	case `if`(conditionals: [(Expression, Block)], else: Block?, at: TokenIndex)
	case forNumerical(variable: Identifier, start: Expression, stop: Expression, increment: Expression?, block: Block, at: TokenIndex)
    case forIn(variables: [Identifier], iterators: [Expression], block: Block, at: TokenIndex)
	case local(variables: [Identifier], values: [Expression], at: TokenIndex)
	case localFunction(name: Identifier, function: Expression, at: TokenIndex)
	case function(names: [Identifier], isMethod: Bool, function: Expression, at: TokenIndex)
    case goto(label: Label, at: TokenIndex)
	case label(label: Label, at: TokenIndex)
    case `return`([Expression], at: TokenIndex)
	case `break`(at: TokenIndex)
    case call(Callable, at: TokenIndex)
    
}

protocol FieldIndex {}

typealias TableItem = (FieldIndex?, Expression)
indirect enum Expression: Assignable, FieldIndex {
	
	case `nil`(at: TokenIndex)
	case varArg(at: TokenIndex)
	case bool(Bool, at: TokenIndex)
	case number(Double, at: TokenIndex)
	case string(String, at: TokenIndex)
    case function([Identifier], Block, isVarArg: Bool, at: TokenIndex)
    case `operator`(NodeOperator, Expression, Expression?, at: TokenIndex)
    case table([TableItem], at: TokenIndex) // table constructor
    case brackets(Expression, at: TokenIndex) // i.e. print((unpack {1, 2, 3})) only prints one, wrapping brackets only gives the first return value
    case call(Callable, at: TokenIndex)
	case variable(Assignable, at: TokenIndex)
    case prefix(Assignable, at: TokenIndex)
	
}

enum Precedence: Int {
	case exponentUnary = 7 // exponent is technically higher, but as its right sided we subtract 1
	case multiplicationDivision = 6
	case additionSubtraction = 5
	case concatenationComparison = 3 // concatention is technically higher, but as its right sided we subtract 1
	case and = 2
	case or = 1
	
	static func <=(lhs: Precedence, rhs: Precedence) -> Bool {
		return lhs.rawValue <= rhs.rawValue
	}
}

enum NodeOperator {
    
    case doubleEqual
    case notEqual
    case lessThanEqual
    case greaterThanEqual
    case concatenate
    case plusPlus
    case minusMinus
    case plusEqual
    case minusEqual
    case multiplyEqual
    case divideEqual
    case modulusEqual
    case exponentEqual
    case equal
    case plus
    case multiply
    case minus
    case hash
    case divide
    case modulus
    case exponent
    case greatherThan
    case lessThan
    case and
	case or
    case not
	
	var isUnary: Bool {
		switch self {
		case .hash, .not, .minus: // minus will always be unary as this is only called on the first token of an expression
			return true
		default:
			return false
		}
	}
	
	static func from(token: Token) -> NodeOperator? {
		switch token {
		case .operator(let op):
			switch op {
			case .hash:
				return .hash
			case .minus:
				return .minus
			case .doubleEqual:
				return .doubleEqual
			case .notEqual:
				return .notEqual
			case .lessThanEqual:
				return .lessThanEqual
			case .greaterThanEqual:
				return .greaterThanEqual
			case .concatenate:
				return .concatenate
			case .plusPlus:
				return .plusPlus
			case .minusMinus:
				return .minusMinus
			case .plusEqual:
				return .plusEqual
			case .minusEqual:
				return .minusEqual
			case .multiplyEqual:
				return .multiplyEqual
			case .divideEqual:
				return .divideEqual
			case .modulusEqual:
				return .modulusEqual
			case .exponentEqual:
				return .exponentEqual
			case .equal:
				return .equal
			case .plus:
				return .plus
			case .multiply:
				return .multiply
			case .divide:
				return .divide
			case .modulus:
				return .modulus
			case .exponent:
				return .exponent
			case .greatherThan:
				return .greatherThan
			case .lessThan:
				return .lessThan
			default: break
			}
		case .keyword(let keyword):
			switch keyword {
			case .not:
				return .not
			case .and:
				return .and
			case .or:
				return .or
			default: break
			}
		default: break
		}
		return nil
	}
	
	func precedence() -> Precedence? {
		switch self {
		case .exponent, .hash, .not:
			return .exponentUnary // technically the same as exponent is right handed
		case .multiply, .divide, .modulus:
			return .multiplicationDivision
		case .plus, .minus:
			return .additionSubtraction
		case .concatenate,
			 .notEqual,
		     .greatherThan,
		     .greaterThanEqual,
		     .lessThan,
		     .lessThanEqual,
		     .doubleEqual:
			return .concatenationComparison // technically the same as concatenation is right handed
		case .and:
			return .and
		case .or:
			return .or
		default:
			return nil // TODO: precedence for customer operators.
		}
	}
	
}

typealias Identifier = String

protocol Callable: Assignable {

	var callee: Assignable { get }
	var arguments: [Expression] { get }

}
struct Call: Callable {
    
    let callee: Assignable
    let arguments: [Expression]
    
}

struct Invocation: Callable {
 
    let callee: Assignable
    let method: Identifier
    let arguments: [Expression]
    
}

protocol Assignable {}
extension Identifier: Assignable, FieldIndex {}
struct ExpressionIndex: Assignable {
	
	let indexed: Assignable
	let index: Expression
	
}

struct IdentifierIndex: Assignable {
	
	let indexed: Assignable
	let index: Identifier
	
}
