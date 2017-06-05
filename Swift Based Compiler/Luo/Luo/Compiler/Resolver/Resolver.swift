//
//  Resolver.swift
//  Luo
//
//  Created by Oliver Cooper on 5/06/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

typealias Name = String

enum ResolverError: Error {
	
	case duplicateName(Name, at: TokenIndex)
	case undefinedObject(Name, at: TokenIndex)
	case multipleSuperClasses(Name, at: TokenIndex)
	case duplicateProtocol(Name, at: TokenIndex)
	
}

struct Resolver {
	
	var objects = [Name: ResolvedObject]()
	
	mutating func resolve(chunks: [Chunk]) throws {
		// first lets get all the barebones structures for all objects
		// at this time we check if there are any duplicate names
		for chunk in chunks {
			for topStatement in chunk {
				let object: ResolvedObject
				switch topStatement {
				case .class(let node, at: let index):
					object = ResolvedClass(node, at: index, resolver: self)
				case .protocol(let node, at: let index):
					object = ResolvedProtocol(node, at: index, resolver: self)
				case .enum(let node, at: let index):
					object = ResolvedEnum(node, at: index, resolver: self)
				default: continue
				}
				
				if objects[object.name] != nil {
					throw ResolverError.duplicateName(object.name, at: object.at)
				}
				
				objects[object.name] = object
			}
		}
		
		// resolve all conforms
		for (_, object) in objects {
			try (object as? Confirming)?.resolveConforms()
		}
	}
	
	func object(named name: Name, at index: TokenIndex) throws -> ResolvedObject {
		if let object = objects[name] {
			return object
		}
		throw ResolverError.undefinedObject(name, at: index)
	}
	
}
