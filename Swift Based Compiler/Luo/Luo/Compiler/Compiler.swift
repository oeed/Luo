//
//  Compiler.swift
//  Luo
//
//  Created by Oliver Cooper on 3/06/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

struct Compiler {
	
	private let lexer: Lexer
	
	var output = ""
	
	private var topScope: Scope
	
	init(abstractSyntaxTree: AbstractSyntaxTree) throws {
		self.lexer = abstractSyntaxTree.lexer
		self.topScope = Scope()
		for statement in abstractSyntaxTree.tree {
			compile(statement: statement, scope: topScope)
		}
	}
	
	private func compile(block: Block, within: inout Scope) {
		let scope = within.subScope()
		for statement in block {
			compile(statement: statement, scope: scope)
		}
	}
	
	private func compile(statement: Statement, scope: Scope) {
		
	}

}
