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
    
    mutating func block(endDelimiter: Bool = true, elseDelimiter: Bool = false, untilDelimiter: Bool = false) throws -> Block {
        var statements = [Statement]()
		while let statement = try statement(endDelimiter: endDelimiter, elseDelimiter: elseDelimiter, untilDelimiter: untilDelimiter) {
            statements.append(statement)
        }
        return statements
    }
	
    mutating func statement(endDelimiter: Bool = false, elseDelimiter: Bool = false, untilDelimiter: Bool = false) throws -> Statement? {
        while let (index, token) = iterator.next() {
			token: switch token {
            case .keyword(let keyword):
                switch keyword {
                case .do:
					return Statement.do(block: try block(), lexer.position(of: index)!)
				case .while:
					return Statement.while(condition: try expression(), block: try block(), lexer.position(of: index)!)
				case .repeat:
					return Statement.repeat(block: try block(endDelimiter: false, untilDelimiter: true), condition: try expression(), lexer.position(of: index)!)
				case .if:
					return try ifStatement(index)
				case .for:
					return try forStatement(index)
				case .end:
					if endDelimiter {
						return nil
					}
					fallthrough //throw ParserError.unexpected(token: token)
				case .else, .elseif:
					if elseDelimiter {
						return nil
					}
					fallthrough //throw ParserError.unexpected(token: token)
				case .until:
					if untilDelimiter {
						return nil
					}
					fallthrough //throw ParserError.unexpected(token: token)
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
			conditionals.append((try expression(), try block(elseDelimiter: true)))
//			we need to check whether the ending keyword of the block was else or end, elseif will just loop again
			switch iterator.lastToken!.1 {
			case .keyword(let keyword):
				switch keyword {
				case .else:
					elseBlock = try block()
				case .end:
					break eachCondition
				default: break
				}
			default: break
			}
		}
		return Statement.if(conditionals: conditionals, else: elseBlock, lexer.position(of: index)!)
	}
	
	mutating func forStatement(_ index: String.Index) throws -> Statement {
		// at this stage we've no idea whether the for loop is a 'for a in b` or `for i = a, b`
		var variables = [Identifier]()
		var isNumerical: Bool?
		var expectComma = false
		variables: while true {
			if let token = iterator.next() {
				token: switch token.1 {
				case .identifier(let identifier):
					if isNumerical != nil, isNumerical! {
						throw ParserError.unexpected(token: token.1)
					} // numerical loops shouldn't have more than one variable
					variables.append(identifier)
					expectComma = true
				case .operator(let op):
					switch op {
						case .comma:
							if expectComma {
								expectComma = false // we have the comma, we can now expect another variable
								isNumerical = false // we now also know that this is not a numerical loop
								break token
							}
//							this comma shouldn't be here
							break
						case .equal:
							if expectComma && (isNumerical == nil || isNumerical!) {
								isNumerical = true
								break variables // we've reached the end of the list of variables
							}
							break // this equal shouldn't be here
						default: break
					}
					throw ParserError.unexpected(token: token.1)
				case .keyword(let keyword):
					switch keyword {
					case .in:
						if expectComma && (isNumerical == nil || !isNumerical!) {
							isNumerical = false
							break variables // we've reached the end of the list of variables
						}
						break  // this `in` shouldn't be here
					default: break
					}
					fallthrough
				default:
					throw ParserError.unexpected(token: token.1)
				}
			}
			else {
				throw ParserError.endOfStream
			}
		}
		
		return Statement.break(lexer.position(of: index)!)
	}
	
}
