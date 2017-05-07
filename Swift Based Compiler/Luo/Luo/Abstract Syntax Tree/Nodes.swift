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
    case apply(Appliable)
    case identifier(Identifier)
    case assignee(Assignable)

}

typealias Block = [Statement]
typealias Label = String
indirect enum Statement {
	
	case `do`(block: Block, Position)
	case set(assignables: [Assignable], expressions: [Expression], Position)
	case `while`(condition: Expression, block: Block, Position)
	case `repeat`(block: Block, condition: Expression, Position)
	case `if`(conditionals: [(Expression, Block)], else: Block?, Position)
	case forNumerical(variable: Identifier, start: Expression, stop: Expression, increment: Expression?, block: Block, Position)
    case forIn(variables: [Identifier], iterators: [Identifier], block: Block, Position)
	case local(variables: [Identifier], value: [Expression], Position)
	case localFunction(name: Identifier, block: Block, Position)
    case goto(label: Label, Position)
    case label(Label, Position)
    case `return`([Expression], Position)
    case `break`(Position)
    case apply(Appliable, Position)
    
}

indirect enum Expression {
	
	case `nil`
	case dots
	case `true`
	case `false`
	case number(Double)
	case string(String)
    case function([Identifier], isVarArg: Bool)
    case `operator`(NodeOperator, Expression, Expression?)
    case table([TableItem]) // table constructor
    case brackets(Expression) // i.e. print((unpack {1, 2, 3})) only prints one, wrapping brackets only gives the first return value
    case apply(Appliable)
    case assignable(Assignable)
	
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
    
}

enum TableItem {
    
    case array(value: Expression) // an array item, added like { a, b }
    case dictionary(key: Expression, value: Expression) // a dictionary item, added like { [a] = b }
    
}

typealias Identifier = String

protocol Appliable {}
struct Call: Appliable {
    
    let callee: Expression
    let arguments: [Expression]
    
}

struct Invocation {
 
    let callee: Expression
    let method: String
    let arguments: [Expression]
    
}

protocol Assignable {}
extension Identifier: Assignable {}
struct Index {
	
	let indexed: Expression
	let index: Expression
	
}