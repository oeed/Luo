//
//  AbstractSyntaxTreeNodes.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

typealias Chunk = [TopStatement]

enum TopStatement {
	
	case `class`(Class, at: TokenIndex)
	case `protocol`(Protocol, at: TokenIndex)
	case `enum`(Enum, at: TokenIndex)
	case statement(Statement, at: TokenIndex)
	
}

struct Class {
	
	let name: Identifier
	let conforms: [Identifier]
	let body: [ClassStatement]
	
}

enum ClassStatement {
	
	case property(name: TypedIdentifier, default: Expression?, at: TokenIndex)
	case `default`(name: Identifier, value: Expression, at: TokenIndex)
	case function(name: Identifier, function: Expression, at: TokenIndex)
	
}

struct Protocol {
	
	let name: Identifier
	let conforms: [Identifier]
	let body: [ProtocolStatement]
	
}

enum ProtocolStatement {
	
	case property(name: TypedIdentifier, at: TokenIndex)
	case function(name: Identifier, parameters: [Parameter], returns: [Type], isVarArg: Bool, at: TokenIndex)
	
}

struct Enum {
	
	let name: Identifier
	let cases: [EnumCase]
	
}

struct EnumCase {
	
	let name: Identifier
	let associatedTypes: [AssociatedType]
	let value: Expression?
	
}
	
struct AssociatedType {

	let name: Identifier?
	let type: Type
	
}

typealias Block = [Statement]
typealias Label = String
indirect enum Statement {
	
	case `do`(block: Block, at: TokenIndex)
	case assignment(assignables: [AssignmentVariable], expressions: [Expression], at: TokenIndex)
	case `while`(condition: Expression, block: Block, at: TokenIndex)
	case `repeat`(block: Block, condition: Expression, at: TokenIndex)
	case `if`(conditionals: [(Expression, Block)], else: Block?, at: TokenIndex)
	case forNumerical(variable: TypedIdentifier, start: Expression, stop: Expression, increment: Expression?, block: Block, at: TokenIndex)
    case forIn(variables: [TypedIdentifier], iterators: [Expression], block: Block, at: TokenIndex)
	case local(variables: [TypedIdentifier], values: [Expression], at: TokenIndex)
	case localFunction(name: Identifier, function: Expression, at: TokenIndex)
	case function(names: [Identifier], isMethod: Bool, function: Expression, at: TokenIndex)
    case goto(label: Label, at: TokenIndex)
	case label(label: Label, at: TokenIndex)
    case `return`([Expression], at: TokenIndex)
	case `break`(at: TokenIndex)
    case call(Callable, at: TokenIndex)
    
}

indirect enum Type {
	
	case optional(Type)
	case array(value: Type, at: TokenIndex)
	case dictionary(key: Type, value: Type, at: TokenIndex)
	case name(name: Identifier, at: TokenIndex)
	case index(parent: Identifier, name: Identifier, at: TokenIndex)
	
}

protocol FieldIndex {}
extension Identifier: FieldIndex {}

typealias TableItem = (FieldIndex?, Expression)
indirect enum Expression: PrefixExpression, FieldIndex {
	
	case `nil`(at: TokenIndex)
	case varArg(at: TokenIndex)
	case bool(Bool, at: TokenIndex)
	case number(Double, at: TokenIndex)
	case string(String, at: TokenIndex)
	case function([Parameter], returns: [Type], isVarArg: Bool, body: Block, at: TokenIndex)
    case `operator`(NodeOperator, Expression, Expression?, at: TokenIndex)
    case table([TableItem], at: TokenIndex) // table constructor
    case brackets(Expression, at: TokenIndex) // i.e. print((unpack {1, 2, 3})) only prints one, wrapping brackets only gives the first return value
    case call(Callable, at: TokenIndex)
	case variable(PrefixExpression, at: TokenIndex)
    case prefix(PrefixExpression, at: TokenIndex)
	case `is`(Expression, type: Type, at: TokenIndex)
	
}

struct Parameter {
	
	let name: Identifier? // the externally accessible name
	let variable: TypedIdentifier // the type and internal name
	let `default`: Expression?
	
}

enum Precedence: Int {
	case postfix = 8 // ++ & --
	case exponentUnary = 7 // exponent is technically higher, but as its right sided we subtract 1
	case multiplicationDivision = 6
	case additionSubtraction = 5
	case concatenationComparison = 3 // concatention is technically higher, but as its right sided we subtract 1
	case and = 2
	case or = 1
	case mutation = 0
	
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
		case .minusMinus, .plusPlus:
			return .postfix
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
		case .plusEqual, .minusEqual, .multiplyEqual, .divideEqual, .modulusEqual, .exponentEqual:
			return .mutation
		}
	}
	
}

protocol PrefixExpression {}

typealias Identifier = String
extension Identifier: PrefixExpression {}

protocol Callable: PrefixExpression {

	var callee: PrefixExpression { get }
	var arguments: [Argument] { get }

}

struct Argument {
	
	let name: Identifier?
	let value: Expression
	
}

struct Call: Callable {
    
    let callee: PrefixExpression
    let arguments: [Argument]
    
}

struct Invocation: Callable {
 
    let callee: PrefixExpression
    let method: Identifier
    let arguments: [Argument]
    
}

protocol AssignmentVariable {}

struct TypedIdentifier: AssignmentVariable {
	
	let identifier: Identifier
	let type: Type?
	
}

struct ExpressionIndex: PrefixExpression, AssignmentVariable {
	
	let indexed: PrefixExpression
	let index: Expression
	
}

struct IdentifierIndex: PrefixExpression, AssignmentVariable {
	
	let indexed: PrefixExpression
	let index: Identifier
	
}
