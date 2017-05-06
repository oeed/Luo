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

typealias FilteredTokenMatch = (pattern: String, filter: (String, String) -> Token?)
typealias TokenMatch = (pattern: String, token: Token?)

let tokenMatches = [
	TokenMatch(pattern: "\\s+", token: nil), // whitespace
	
	FilteredTokenMatch(pattern: "0x[\\da-fA-F]+", filter: {(_ match: String, _) -> Token? in
		//		TODO: in Lua this will be done by tonumber
		return Token.number(42)
	}), // hex numbers
	
	FilteredTokenMatch(pattern: "[a-zA-Z_][\\w_]*", filter: {(_ identifier: String, _) -> Token? in
		if let keyword = Keyword(rawValue: identifier) {
			return Token.keyword(keyword)
		}
		return Token.identifier(identifier)
	}), // identifiers
	
	FilteredTokenMatch(pattern: "\\d+\\.?\\d*[eE][\\+\\-]?\\d+", filter: {(_ match: String, _) -> Token? in
		//		TODO: in Lua this will be done by tonumber
		return Token.number(42)
	}), // scientific numbers
	
	FilteredTokenMatch(pattern: "\\d+\\.?\\d*", filter: {(_ match: String, _) -> Token? in
		//		TODO: in Lua this will be done by tonumber
		return Token.number(42)
	}), // decimal numbers
	
	TokenMatch(pattern: "(['\"])\\1", token: Token.string("")), // empty string
	
	FilteredTokenMatch(pattern: "[(['\"])(\\*)\\2\\1", {(_ match: String, _) -> Token? in
		return Token.string(match.substring(to: match.index(before: match.endIndex)))
	}), // string
	
	FilteredTokenMatch(pattern: "(['\"]).-[^\\](\\*)\\2\\1", {(_ match: String, _) -> Token? in
		return Token.string(match)
	}), // string with escapes
	
	TokenMatch(pattern: "\\-\\-\\[(=*)\\[.-\\]\\1\\]", token: nil), // multi-line comment
	
	TokenMatch(pattern: "\\-\\-.-\n", token: nil), // single line comment
	
	FilteredTokenMatch(pattern: "\\[(=*)\\[.-\\]\\1\\]", filter: {(_ match: String, _ commentLevel: String) -> Token? in
		return Token.string(match)
	}), // multi-line string
	
	TokenMatch(pattern: ":", token: Token.operator(.typeSet)),
	TokenMatch(pattern: "?", token: Token.operator(.optional)),
	TokenMatch(pattern: "==", token: Token.operator(.doubleEqual)),
	TokenMatch(pattern: "~=", token: Token.operator(.notEqual)),
	TokenMatch(pattern: "<=", token: Token.operator(.lessThanEqual)),
	TokenMatch(pattern: ">=", token: Token.operator(.greaterThanEqual)),
	TokenMatch(pattern: "\\.\\.\\.", token: Token.operator(.varArg)),
	TokenMatch(pattern: "\\.\\.", token: Token.operator(.concatenate)),
	TokenMatch(pattern: "++", token: Token.operator(.plusPlus)),
	TokenMatch(pattern: "\\-\\-", token: Token.operator(.minusMinus)),
	TokenMatch(pattern: "+=", token: Token.operator(.plusEqual)),
	TokenMatch(pattern: "\\-=", token: Token.operator(.minusEqual)),
	TokenMatch(pattern: "*=", token: Token.operator(.multiplyEqual)),
	TokenMatch(pattern: "/=", token: Token.operator(.divideEqual)),
	TokenMatch(pattern: "\\=", token: Token.operator(.modulusEqual)),
	TokenMatch(pattern: "\\^=", token: Token.operator(.exponentEqual)),
	TokenMatch(pattern: "=", token: Token.operator(.equal)),
	TokenMatch(pattern: "+", token: Token.operator(.plus)),
	TokenMatch(pattern: "*", token: Token.operator(.multiply)),
	TokenMatch(pattern: "\\-", token: Token.operator(.minus)),
	TokenMatch(pattern: "#", token: Token.operator(.hash)),
	TokenMatch(pattern: "/", token: Token.operator(.divide)),
	TokenMatch(pattern: "%", token: Token.operator(.modulus)),
	TokenMatch(pattern: "\\^", token: Token.operator(.exponent)),
	TokenMatch(pattern: ">", token: Token.operator(.greatherThan)),
	TokenMatch(pattern: "<", token: Token.operator(.lessThan)),
	TokenMatch(pattern: "\\.", token: Token.operator(.dot)),
	TokenMatch(pattern: "\\[", token: Token.operator(.squareBracketLeft)),
	TokenMatch(pattern: "\\]", token: Token.operator(.squareBracketRight)),
	TokenMatch(pattern: "\\(", token: Token.operator(.roundBracketLeft)),
	TokenMatch(pattern: "\\)", token: Token.operator(.roundBracketRight)),
	TokenMatch(pattern: "{", token: Token.operator(.curlyBracketLeft)),
	TokenMatch(pattern: "}", token: Token.operator(.curlyBracketRight)),
	TokenMatch(pattern: ",", token: Token.operator(.comma))
	] as [Any]
