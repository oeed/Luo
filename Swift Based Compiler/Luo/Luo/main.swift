//
//  main.swift
//  Luo
//
//  Created by Oliver Cooper on 22/04/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

print("Hello, World!")
let lexer = Lexer(path: "/Users/olivercooper/Dropbox/Documents/Projects/Luo/Lexer/Example.luo")!

for token in lexer {
	print(token)
}
