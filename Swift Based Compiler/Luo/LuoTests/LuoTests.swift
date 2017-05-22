//
//  LuoTests.swift
//  LuoTests
//
//  Created by Oliver Cooper on 22/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import XCTest
import Luo

class LuoTests: XCTestCase {
	
	var lexer: Lexer!
	
    override func setUp() {
        super.setUp()
		lexer = Lexer(path: "/Users/olivercooper/Dropbox/Documents/Projects/Luo/Lexer/Test.luo")
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
    
    func testLexerIterationPerformance() {
        // This is an example of a performance test case.
		
        self.measure {
			for token in self.lexer {
				
			}
        }
		
    }
	
	func testAstBuildingPerformance() {
		self.measure {
			do {
				let tree = try AbstractSyntaxTree(lexer: self.lexer)
			} catch {}
		}
	}
    
}
