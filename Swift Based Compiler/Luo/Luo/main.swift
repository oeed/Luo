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
    for token in lexer {
        print(token)
    }
}
else {
    print("Unable to open file: " + CommandLine.arguments[1])
}

