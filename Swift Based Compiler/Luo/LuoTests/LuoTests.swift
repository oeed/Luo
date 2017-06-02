//
//  LuoTests.swift
//  LuoTests
//
//  Created by Oliver Cooper on 22/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import XCTest
import Luo

extension Token: Equatable {
    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case let (.number(a), .number(b)):
            return a == b
        case let (.string(a), .string(b)):
            return a == b
        case let (.keyword(a), .keyword(b)):
            return a == b
        case let (.identifier(a), .identifier(b)):
            return a == b
        case let (.operator(a), .operator(b)):
            return a == b
        default:
            return false
        }
    }
}

class LuoTests: XCTestCase {
	
	var lexer: Lexer!
	
    override func setUp() {
        super.setUp()
        do {
            self.lexer = try Lexer(path: "/Users/olivercooper/Dropbox/Documents/Projects/Luo/Swift Based Compiler/Luo/LuoTests/Cases/Iterator.luo")!
        } catch {}
		//tree = try AbstractSyntaxTree(lexer: lexer)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testLexerIteratorMovement() {
        var iterator = lexer.makeIterator()
        XCTAssertEqual(iterator.next()!.1, Token.identifier("one"))
        XCTAssertEqual(iterator.next()!.1, Token.operator(.equal))
        iterator.undo()
        XCTAssertEqual(iterator.next()!.1, Token.operator(.equal))
        XCTAssertEqual(iterator.next()!.1, Token.number(1))
        XCTAssertEqual(iterator.lastToken!.1, Token.number(1), "Lookbehind")
        XCTAssertEqual(iterator.lookAhead!.1, Token.identifier("two"), "Lookahead")
        
    }
    
    func testLexerIterationPerformance() {
        // This is an example of a performance test case.
		
        self.measure {
            do {
                try Lexer(path: "/Users/olivercooper/Dropbox/Documents/Projects/Luo/Lexer/Test.luo")
            }
            catch {}
        }
		
    }
//
//	func testAstBuildingPerformance() {
//        do{
//        self.lexer = try Lexer(path: "/Users/olivercooper/Dropbox/Documents/Projects/Luo/Lexer/Test.luo")!
//        }catch{}
//		self.measure {
//			do {
//				let tree = try AbstractSyntaxTree(lexer: self.lexer)
//			} catch {}
//		}
//	}
    
}
