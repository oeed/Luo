//
//  AbstractSyntaxTree.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation
import Cocoa

enum ParserError: Error {
    case unexpected(token: Token)
    case endOfStream
}

struct AbstractSyntaxTree {
    
    let tree = [Node]()
    private var iterator: LexerIterator
    private let lexer: Lexer
    
    init(lexer: Lexer) throws {
        var tree = [Node]()
        iterator = lexer.makeIterator()
        self.lexer = lexer
		try block()
    }
    
    mutating func block() throws -> Block {
        var statements = [Statement]()
        while let statement = try statement(true) {
            statements.append(statement)
        }
        return statements
    }
	
    mutating func statement(_ expectBlockDelimiter: Bool = false) throws -> Statement? {
        while let (index, token) = iterator.next() {
            switch token {
            case .keyword(let keyword):
                switch keyword {
                case .do:
					return Statement.do(block: try block(), lexer.position(of: index)!)
				case .while:
					return Statement.while(condition: try expression(), block: try block(), lexer.position(of: index)!)
				case .repeat:
					return Statement.repeat(block: try block(), condition: try expression(), lexer.position(of: index)!)
				case .if:
					return try ifStatement(index)
				case .end, .until, .else:
					if expectBlockDelimiter {
						return nil
					}
					throw ParserError.unexpected(token: token)
                default:
                    throw ParserError.unexpected(token: token)
                }
            default:
                throw ParserError.unexpected(token: token)
            }
        }
        return nil
    }
	
	mutating func expression() throws -> Expression {
		return Expression.dots
	}
	
	mutating func ifStatement(_ index: String.Index) throws -> Statement {
		var conditionals = [(Expression, Block)]()
		var elseBlock: Block?
		eachCondition: while true {
			conditionals.append((try expression(), try block()))
			
//			we need to check whether the ending keyword of the block was else or end, elseif will just loop again
			switch iterator.lastToken!.1 {
			case .keyword(let keyword):
				switch keyword {
				case .else:
					elseBlock = try block()
				case .until:
					ParserError.unexpected(token: iterator.lastToken!.1)
				case .end:
					break eachCondition
				default: break
				}
			default: break
			}
		}
		return Statement.if(conditionals: conditionals, else: elseBlock, lexer.position(of: index)!)
	}
	
}
