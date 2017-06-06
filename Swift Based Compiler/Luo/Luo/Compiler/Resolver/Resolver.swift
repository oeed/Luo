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
	case undefinedType(Name, at: TokenIndex)
	case duplicateType(Name, at: TokenIndex)
    case invalidIndex(Name, at: TokenIndex)
    case invalidIndexedType(Name, at: TokenIndex)
	
}

typealias TypeAlias = (of: Type, at: TokenIndex)

struct Resolver {
	
	var objects = [Name: ResolvedObject]()
	var types = [Name: ResolvedObject]() // sometimes
	
	mutating func resolve(chunks: [Chunk]) throws {
		// first lets get all the barebones structures for all objects
		// at this time we check if there are any duplicate names
//		var typeAliases = [Name: TypeAlias]()
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
//				case .typeAlias(let name, of: let aliases, at: let index):
//					typeAliases[name] = (of: aliases, at: index)
				default: continue
				}
				
				if objects[object.name] != nil {
					throw ResolverError.duplicateName(object.name, at: object.at)
				}
				
				objects[object.name] = object
				types[object.name] = object
			}
		}
		
		// resolve typealiases
//		for (name, typeAlias) in typeAliases {
//			try addAlias(name: name, typeAlias: typeAlias, remaining: &typeAliases)
//		}
		
		// resolve all conforms
		for (_, object) in objects {
			try (object as? Conforming)?.resolveConforms()
		}
	}
	
	mutating func addAlias(name: Name, typeAlias: TypeAlias, remaining: inout [Name: TypeAlias]) throws {
		// check that it hasn't already been defined
		if types[name] != nil {
			throw ResolverError.duplicateType(name, at: typeAlias.at)
		}
		
//		types[name] =
	}
	
//	mutating func type(_ node: Type) throws ->
//	
//	mutating func type(named name: Name, at index: TokenIndex) throws -> ResolvedObject {
//		
//	}
	
	func object(named name: Name, at index: TokenIndex) throws -> ResolvedObject {
		if let object = objects[name] {
			return object
		}
		throw ResolverError.undefinedObject(name, at: index)
	}
	
}
