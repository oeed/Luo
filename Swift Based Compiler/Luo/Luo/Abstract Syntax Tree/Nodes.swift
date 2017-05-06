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
	case identifier(Identifier)
	case assignee(Assignable)

}

typealias Block = [Statement]
indirect enum Statement {
	
	case `do`(statements: [Statement])
	case set(assignables: [Assignable], expressions: [Expression])
	case `while`(condition: Expression, block: Block)
	case `repeat`(block: Block, condition: Expression)
	case `if`(conditionals: [(Expression, Block)], else: Block?)
	case forNumerical(variable: Identifier, start: Expression, stop: Expression, increment: Expression?, block: Block)
	case forIn(variables: [Identifier], iterators: [Identifier], Block)
	case local(variables: [Identifier], value: [Expression])
	case localFunction(name: Identifier, block: Block)
}

enum Expression {
	
	case `nil`
	case dots
	case `true`
	case `false`
	case number(Double)
	case string(String)
	case function([Identifier], isVarArg: Bool)
	
}

typealias Identifier = String

protocol Assignable {}
extension Identifier: Assignable {}
struct Index {
	
	let indexed: Expression
	let index: Expression
	
}
