//
//  Scope.swift
//  Luo
//
//  Created by Oliver Cooper on 3/06/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

struct Scope {
	
	var children = [Scope]()
	
	mutating func subScope() -> Scope {
		let scope = Scope()
		children.append(scope)
		return scope
	}
	
}
