//
//  main.swift
//  Luo
//
//  Created by Oliver Cooper on 22/04/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

print("Hello, World!")
if CommandLine.arguments.count != 2 {
    print("Expects 1 argument: luo <path>")
}

if let lexer = Lexer(path: CommandLine.arguments[1]) {
	do {
		let _ = try AbstractSyntaxTree(lexer: lexer)
    }
    catch ParserError.unexpected(token: let token, at: let index) {
        let position = lexer.position(of: index)!
        print("Unexpected: \(token) at line: \(position.line) col: \(position.column)")
    }
    catch ParserError.expectedExpression(at: let index) {
        let position = lexer.position(of: index)!
        print("Expected expression at line: \(position.line) col: \(position.column)")
    }
}
else {
    print("Unable to open file: " + CommandLine.arguments[1])
}
