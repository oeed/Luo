//
//  LexerTokens.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

enum Token {
	case number(Double)
	case string(String)
	case keyword(Keyword)
	case identifier(String)
	case `operator`(Operator)
}

enum Operator {
	case typeSet
	case optional
	case doubleEqual
	case notEqual
	case lessThanEqual
	case greaterThanEqual
	case varArg
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
	case dot
	case squareBracketLeft
	case squareBracketRight
	case roundBracketLeft
	case roundBracketRight
	case curlyBracketLeft
	case curlyBracketRight
	case comma
}

enum Keyword: String {
	case and = "and"
	case `break` = "break"
	case `do` = "do"
	case `else` = "else"
	case elseif = "elseif"
	case end = "end"
	case `false` = "false"
	case `for` = "for"
	case function = "function"
	case `if` = "if"
	case `in` = "in"
	case local = "local"
	case `nil` = "nil"
	case not = "not"
	case or = "or"
	case `repeat` = "repeat"
	case `return` = "return"
	case then = "then"
	case until = "until"
	case `while` = "while"
	case `class` = "class"
	case property = "property"
	case `is` = "is"
	case `enum` = "enum"
}

typealias FilteredTokenMatch = (pattern: String, filter: (String) -> Token?)
typealias TokenMatch = (pattern: String, token: Token?)
