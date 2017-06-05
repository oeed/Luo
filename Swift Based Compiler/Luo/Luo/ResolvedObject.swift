//
//  ResolvedNode.swift
//  Luo
//
//  Created by Oliver Cooper on 5/06/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

protocol ResolvedObject {
	
	var at: TokenIndex { get }
	var name: Name { get }

}

protocol Confirming {
	
	func resolveConforms() throws
	
}

protocol Conformable {
	
}

class ResolvedClass: ResolvedObject, Conformable, Confirming {
	
	let name: Name
	let node: Class
	let at: TokenIndex
	
	private let resolver: Resolver
	
	var superClass: ResolvedClass?
	var protocols = [ResolvedProtocol]()
	
	init(_ node: Class, at: TokenIndex, resolver: Resolver) {
		self.resolver = resolver
		self.name = node.name
		self.node = node
		self.at = at
	}
	
	private var hasResolvedConforms = false
	func resolveConforms() throws {
		if hasResolvedConforms {
			return
		}
		hasResolvedConforms = true
		for (name, index) in node.conforms {
			let object = try resolver.object(named: name, at: index)
			if object is ResolvedClass {
				if superClass != nil {
					// only one super class is allowed
					throw ResolverError.multipleSuperClasses(name, at: index)
				}
				superClass = object as? ResolvedClass
				try superClass?.resolveConforms()
				
				// now inherit all of the super classes
				for proto in superClass!.protocols {
					try add(protocol: proto, at: index)
				}
			}
			else {
				// object must be a protocol
				try add(protocol: object as! ResolvedProtocol, at: index)
			}
		}
	}
	
	func add(protocol added: ResolvedProtocol, at index: TokenIndex) throws {
		// check that the protocol isn't already being conformed to
		for proto in protocols {
			if proto === added {
				throw ResolverError.duplicateProtocol(added.name, at: index)
			}
		}
		
		protocols.append(added)
	}
	
}

class ResolvedProtocol: ResolvedObject, Conformable {
	
	let name: Name
	let node: Protocol
	let at: TokenIndex
	
	private let resolver: Resolver
	
	//var conforms: [Conformable]
	
	init(_ node: Protocol, at: TokenIndex, resolver: Resolver) {
		self.resolver = resolver
		self.name = node.name
		self.node = node
		self.at = at
	}
	
}

class ResolvedEnum: ResolvedObject {
	
	let name: Name
	let node: Enum
	let at: TokenIndex
	
	private let resolver: Resolver
	
	init(_ node: Enum, at: TokenIndex, resolver: Resolver) {
		self.resolver = resolver
		self.name = node.name
		self.node = node
		self.at = at
	}
	
}
