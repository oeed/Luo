//
//  Lexer.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

struct LexerIterator: IteratorProtocol {
	
	let lexer: Lexer
	
	var index: String.Index
	
	var lineIndex: Int = 1
	
	init(_ lexer: Lexer) {
		self.lexer = lexer
		index = lexer.source.startIndex
	}
	
	mutating func next() -> Token? {
		return lexer.token(at: &index)
	}
	
}

struct Lexer: Sequence {
	
	let source: String
	
	init(source: String) {
		self.source = source
	}
	
	func makeIterator() -> LexerIterator {
		return LexerIterator(self)
	}
	
	init?(path: String) {
		if let source = try? String.init(contentsOfFile: path) {
			self.init(source: source)
		}
		return nil
	}
	
	func token(at index: inout String.Index) -> Token? {
		for tokenMatch in tokenMatches {
			let str: String = ""
			if let range = source.range(of: tokenMatch.pattern, options: .regularExpression, range: index..<str.endIndex, locale: nil) {
				// the is our next match
				if tokenMatch is FilteredTokenMatch {
					//					match.range
					index = source.index(after: range.upperBound)
					return (tokenMatch as! FilteredTokenMatch).filter(source.substring(with: range), "")
				}
			}
		}
		return nil
	}
	
}
