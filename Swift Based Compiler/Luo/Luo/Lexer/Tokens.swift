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
	case identifier(Identifier)
	case `operator`(Operator)
}

enum Operator { // TOD: Lua 5.3 binary operators
	case doubleColon
	case colon
	case semicolon
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
	case `protocol` = "protocol"
	case `default` = "default"
	case `is` = "is"
	case `enum` = "enum"
	case goto = "goto"
	case `true` = "true"
	case `false` = "false"
}

protocol TokenMatchable {
	
	var pattern: String { get }
	
}

struct FilteredTokenMatch: TokenMatchable {
	
	let pattern: String
	let filter: (String, String) -> Token
	
	init(_ pattern: String, _ filter: @escaping (String, String) -> Token) {
		self.pattern = pattern
		self.filter = filter
	}
	
}

struct TokenMatch: TokenMatchable {
	
	let pattern: String
	let token: Token?
	
	init(_ pattern: String, _ token: Token? = nil) {
		self.pattern = pattern
		self.token = token
	}
	
}

let tokenMatches: [TokenMatchable] = [
	TokenMatch("\\s+"), // whitespace
	
	FilteredTokenMatch("0x[\\da-fA-F]+") {(_ match: String, _) -> Token in // hex numbers
		return Token.number(Double(match)!)
	},
	
	FilteredTokenMatch("[a-zA-Z_][\\w_]*") {(_ identifier: String, _) -> Token in // identifiers
		if let keyword = Keyword(rawValue: identifier) {
			return Token.keyword(keyword)
		}
		return Token.identifier(identifier)
	},
	
	FilteredTokenMatch("\\d+\\.?\\d*[eE][\\+-]?\\d+") {(_ match: String, _) -> Token in // scientific numbers
		return Token.number(Double(match)!)
	},
	
	FilteredTokenMatch("\\d+\\.?\\d*") {(_ match: String, _) -> Token in // decimal numbers
		return Token.number(Double(match)!)
	},
	
	TokenMatch("(['\"])\\1", Token.string("")), // empty string
	
	FilteredTokenMatch("(['\"]).*?[^\\\\](\\*)\\2\\1") {(_ match: String, _) -> Token in // string
		return Token.string(match.substring(to: match.index(before: match.endIndex)))
	},
	
	FilteredTokenMatch("(['\"]).*?[^\\\\](\\\\*)\\2\\1") {(_ match: String, _) -> Token in // string with escapes
		return Token.string(match)
	},
	
	TokenMatch("--\\[(=*)\\[[\\S\\s]*?\\]\\1\\]"), // multi-line comment
	
	TokenMatch("--.*?(?:\\n|$)"), // single line comment
	
	FilteredTokenMatch("\\[(=*)\\[[\\S\\s]*?\\]\\1\\]") {(_ match: String, _ commentLevel: String) -> Token in // multi-line string
		return Token.string(match)
	},
	
	TokenMatch("::", Token.operator(.doubleColon)),
	TokenMatch(":", Token.operator(.colon)),
	TokenMatch(";", Token.operator(.semicolon)),
	TokenMatch("\\?", Token.operator(.optional)),
	TokenMatch("==", Token.operator(.doubleEqual)),
	TokenMatch("~=", Token.operator(.notEqual)),
	TokenMatch("<=", Token.operator(.lessThanEqual)),
	TokenMatch(">=", Token.operator(.greaterThanEqual)),
	TokenMatch("\\.\\.\\.", Token.operator(.varArg)),
	TokenMatch("\\.\\.", Token.operator(.concatenate)),
	TokenMatch("\\+\\+", Token.operator(.plusPlus)),
	TokenMatch("--", Token.operator(.minusMinus)),
	TokenMatch("\\+=", Token.operator(.plusEqual)),
	TokenMatch("-=", Token.operator(.minusEqual)),
	TokenMatch("\\*=", Token.operator(.multiplyEqual)),
	TokenMatch("/=", Token.operator(.divideEqual)),
	TokenMatch("%=", Token.operator(.modulusEqual)),
	TokenMatch("\\^=", Token.operator(.exponentEqual)),
	TokenMatch("=", Token.operator(.equal)),
	TokenMatch("\\+", Token.operator(.plus)),
	TokenMatch("\\*", Token.operator(.multiply)),
	TokenMatch("-", Token.operator(.minus)),
	TokenMatch("#", Token.operator(.hash)),
	TokenMatch("/", Token.operator(.divide)),
	TokenMatch("%", Token.operator(.modulus)),
	TokenMatch("\\^", Token.operator(.exponent)),
	TokenMatch(">", Token.operator(.greatherThan)),
	TokenMatch("<", Token.operator(.lessThan)),
	TokenMatch("\\.", Token.operator(.dot)),
	TokenMatch("\\[", Token.operator(.squareBracketLeft)),
	TokenMatch("\\]", Token.operator(.squareBracketRight)),
	TokenMatch("\\(", Token.operator(.roundBracketLeft)),
	TokenMatch("\\)", Token.operator(.roundBracketRight)),
	TokenMatch("\\{", Token.operator(.curlyBracketLeft)),
	TokenMatch("\\}", Token.operator(.curlyBracketRight)),
	TokenMatch(",", Token.operator(.comma))
]
