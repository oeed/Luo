//
//  Lexer.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

typealias TokenIndex = Int
typealias SourceIndex = String.Index
struct Position {
	
	let line: Int
	let column: Int
    let lexer: Lexer
	
}

enum LexerError: Error {
	
	case unexpectedCharacter(Position)
	case endOfFile
	
}

struct LexerIterator: IteratorProtocol {
	
	let tokens: [Token]
    var nextIndex: TokenIndex
    var lastToken: (TokenIndex, Token)?
	
    var lookAhead: (TokenIndex, Token)? {
        return self[nextIndex]
    }
    
    let lexer: Lexer
    
    subscript (_ index: TokenIndex) -> (TokenIndex, Token)? {
        if let token = tokens[safe: index] {
            return (index, token)
        }
        return nil
    }
    
	
    init(_ tokens: [Token], lexer: Lexer) {
		self.tokens = tokens
		nextIndex = tokens.startIndex
        self.lexer = lexer
    }
	
	mutating func next() -> (TokenIndex, Token)? {
        lastToken = self[nextIndex]
        nextIndex = tokens.index(after: nextIndex)
		return lastToken
	}
	
	mutating func skip() {
		nextIndex = tokens.index(after: nextIndex)
	}
	
	mutating func undo() {
        nextIndex = tokens.index(before: nextIndex)
	}
	
}

struct Lexer: Sequence {
	
	let source: String
	
	private let lineRanges: [ClosedRange<String.Index>]
    
    let tokens: [Token]
    private let indicies: [SourceIndex]
    
    init?(path: String) throws {
        if let source = try? String(contentsOfFile: path) {
            try self.init(source: source)
        }
        else {
            return nil
        }
    }
	
	init(source: String) throws {
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
        
        var theTokens = [Token]()
        var theIndicies = [SourceIndex]()
        var index = source.startIndex
        index: while index < source.endIndex {
            for tokenMatch in tokenMatches {
                if let range = source.range(of: "^" + tokenMatch.pattern, options: .regularExpression, range: index ..< source.endIndex, locale: nil) {
                    // the is our next match
                    index = range.upperBound // source.index(range.upperBound, offsetBy: 1, limitedBy: source.endIndex) ?? source.endIndex
                    if tokenMatch is FilteredTokenMatch {
                        theTokens.append((tokenMatch as! FilteredTokenMatch).filter(source.substring(with: range), ""))
                        theIndicies.append(range.lowerBound)
                    }
                    else if let token = (tokenMatch as! TokenMatch).token {
                        theTokens.append(token)
                        theIndicies.append(range.lowerBound)
                    }
                    continue index
                }
            }
            tokens = theTokens // these two are here only to shut up a 'self not initialised' error
            indicies = theIndicies
            throw LexerError.unexpectedCharacter(position(of: index)!)
        }
        tokens = theTokens
        indicies = theIndicies
    }
    
	
	func makeIterator() -> LexerIterator {
        return LexerIterator(tokens, lexer: self)
	}
    
	func position(of index: SourceIndex) -> Position? {
		for (line, range) in lineRanges.enumerated() {
			if range ~= index {
                return Position(line: line + 1, column: source.distance(from: range.lowerBound, to: index), lexer: self)
			}
		}
		return nil
    }
    
    func position(of index: TokenIndex) -> Position? {
        let sourceIndex = indicies[safe: index]
        if sourceIndex != nil {
            return position(of: sourceIndex!)
        }
        return nil
    }

}
