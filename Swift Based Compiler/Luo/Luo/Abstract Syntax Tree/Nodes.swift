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
	
	case `do`(block: Block, Position)
	case assignment(assignables: [Assignable], expressions: [Expression], Position)
	case `while`(condition: Expression, block: Block, Position)
	case `repeat`(block: Block, condition: Expression, Position)
	case `if`(conditionals: [(Expression, Block)], else: Block?, Position)
	case forNumerical(variable: Identifier, start: Expression, stop: Expression, increment: Expression?, block: Block, Position)
    case forIn(variables: [Identifier], iterators: [Expression], block: Block, Position)
	case local(variables: [Identifier], values: [Expression], Position)
	case localFunction(name: Identifier, function: Expression, Position)
	case function(names: [Identifier], isMethod: Bool, function: Expression, Position)
    case goto(label: Label, Position)
	case label(label: Label, Position)
    case `return`([Expression], Position)
    case `break`(Position)
    case call(Callable, Position)
    
}

indirect enum Expression: Assignable {
	
	case `nil`
	case varArg
	case bool(Bool)
	case number(Double)
	case string(String)
    case function([Identifier], Block, isVarArg: Bool)
    case `operator`(NodeOperator, Expression, Expression?)
    case table([TableItem]) // table constructor
    case brackets(Expression, Position) // i.e. print((unpack {1, 2, 3})) only prints one, wrapping brackets only gives the first return value
    case call(Callable)
	case variable(Assignable, Position)
    case prefix(Assignable, Position)
	
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
    case not
	
	static func from(token: Token) -> NodeOperator? {
		switch token {
		case .operator(let op):
			switch op {
			case .hash:
				return .hash
			case .minus:
				return .minus
			default: break
			}
		case .keyword(let keyword):
			switch keyword {
			case .not:
				return .not
			default: break
			}
		default: break
		}
		return nil
	}
	
}

enum TableItem {
    
    case array(value: Expression) // an array item, added like { a, b }
    case dictionary(key: Expression, value: Expression) // a dictionary item, added like { [a] = b }
    
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
extension Identifier: Assignable {}
struct ExpressionIndex: Assignable {
	
	let indexed: Assignable
	let index: Expression
	
}

struct IdentifierIndex: Assignable {
	
	let indexed: Assignable
	let index: Identifier
	
}
