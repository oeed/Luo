//
//  Lexer.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

struct Position {
	
	let line: Int
	let column: Int
	
}

enum LexerError: Error {
	
	case unexpectedCharacter(Position)
	
}

struct LexerIterator: IteratorProtocol {
	
	let lexer: Lexer
	
	var index: String.Index
	
	var lineIndex: Int = 1
	
	init(_ lexer: Lexer) {
		self.lexer = lexer
		index = lexer.source.startIndex
	}
	
	mutating func next() -> Token?? {
		do {
			return try lexer.token(at: &index)
		}
		catch LexerError.unexpectedCharacter(let position) {
			print("Unknown character at: \(position.line), \(position.column)")
			return nil
		}
		catch {
			print("Uncaught error.")
		}
		return nil
	}
	
}

struct Lexer: Sequence {
	
	let source: String
	
	private let lineRanges: [ClosedRange<String.Index>]
	
	init(source: String) {
		self.source = source
		
		var startIndex = source.startIndex
		var lineRanges = [ClosedRange<String.Index>]()
		for line in source.components(separatedBy: "\n") {
			let range = startIndex ... (source.index(startIndex, offsetBy: line.characters.count, limitedBy: source.endIndex) ?? source.endIndex)
			lineRanges.append(range)
			if range.upperBound < source.endIndex {
				startIndex = source.index(after: range.upperBound)
			}
		}
		self.lineRanges = lineRanges
	}
	
	func makeIterator() -> LexerIterator {
		return LexerIterator(self)
	}
	
	init?(path: String) {
		if let source = try? String(contentsOfFile: path) {
			self.init(source: source)
		}
		else {
			return nil
		}
	}
	
	func position(of index: String.Index) -> Position? {
		for (line, range) in lineRanges.enumerated() {
			if range ~= index {
				return Position(line: line + 1, column: source.distance(from: range.lowerBound, to: index))
			}
		}
		return nil
	}
	
	func token(at index: inout String.Index) throws -> Token?? {
		if index == source.endIndex {
			return nil
		}
		for tokenMatch in tokenMatches {
			if let range = source.range(of: "^" + tokenMatch.pattern, options: .regularExpression, range: index ..< source.endIndex, locale: nil) {
				// the is our next match
				index = source.index(range.upperBound, offsetBy: 1, limitedBy: source.endIndex) ?? source.endIndex
				if tokenMatch is FilteredTokenMatch {
					return Optional((tokenMatch as! FilteredTokenMatch).filter(source.substring(with: range), ""))
				}
				else {
					print(source.substring(with: range))
					return Optional<Token?>((tokenMatch as! TokenMatch).token)
				}
			}
		}
		throw LexerError.unexpectedCharacter(position(of: index)!)
	}
	
}
