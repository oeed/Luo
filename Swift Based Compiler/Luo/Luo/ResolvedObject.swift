//
//  ResolvedNode.swift
//  Luo
//
//  Created by Oliver Cooper on 5/06/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

protocol ResolvedObject {
		
    var name: Name { get }
    var at: TokenIndex { get }

}

protocol Conforming {
    
    var protocols: [ResolvedProtocol] { get set }
	func resolveConforms() throws
	
}

protocol Conformable {
	
}

class ResolvedClass: ResolvedObject, Conformable, Conforming {
	
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

class ResolvedProtocol: ResolvedObject, Conformable, Conforming {
	
	let name: Name
	let node: Protocol
	let at: TokenIndex
	
	private let resolver: Resolver
    
    var protocols = [ResolvedProtocol]()
	//var conforms: [Conformable]
	
	init(_ node: Protocol, at: TokenIndex, resolver: Resolver) {
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

indirect enum ResolvedType {
    
    case any
    case optional(ResolvedType)
    case array(value: ResolvedType)
    case dictionary(key: ResolvedType, value: ResolvedType)
    case `protocol`(ResolvedProtocol)
    case instance(of: ResolvedClass)
    case `enum`(ResolvedEnum)
    case metaClass(ResolvedClass)
    case metaProtocol(ResolvedProtocol)
    
    init(type: Type, resolver: Resolver) throws {
        switch type {
        case .optional(let subType):
            self = .optional(try ResolvedType(type: subType, resolver: resolver))
        case .array(value: let value, at: _):
            self = .array(value: try ResolvedType(type: value, resolver: resolver))
        case .dictionary(key: let key, value: let value, at: _):
            self = .dictionary(key: try ResolvedType(type: key, resolver: resolver), value: try ResolvedType(type: value, resolver: resolver))
        case .name(name: let name, at: let index):
            let object = try resolver.object(named: name, at: index)
            if object is ResolvedClass {
                self = .instance(of: object as! ResolvedClass)
            }
            else if object is ResolvedProtocol {
                self = .protocol(object as! ResolvedProtocol)
            }
            else {
                self = .enum(object as! ResolvedEnum)
            }
        case .index(parent: let parent, name: let name, at: let index):
            if name != "Type" {
                throw ResolverError.invalidIndex(name, at: index)
            }
            
            let object = try resolver.object(named: parent, at: index)
            if object is ResolvedClass {
                self = .metaClass(object as! ResolvedClass)
            }
            else if object is ResolvedProtocol {
                self = .metaProtocol(object as! ResolvedProtocol)
            }
            else {
                throw ResolverError.invalidIndexedType(parent, at: index)
            }
        }
    }
    
    // check if the both types are an exact match (for protocols)
    static func ==(_ lhs: ResolvedType, _ rhs: ResolvedType) -> Bool {
        // all of these need to be exact matches
        switch lhs {
        case .any:
            // any can be anything except optional
            switch rhs {
            case .optional(_):
                return false
            default:
                return true
            }
        case .optional(let lhsSub):
            switch rhs {
            case .optional(let rhsSub):
                return lhsSub == rhsSub
            default:
                return false
            }
        case .array(value: let lhsValue):
            switch rhs {
            case .array(value: let rhsValue):
                return lhsValue == rhsValue
            default:
                return false
            }
        case .dictionary(key: let lhsKey, value: let lhsValue):
            switch rhs {
            case .dictionary(key: let rhsKey, value: let rhsValue):
                return lhsKey == rhsKey && lhsValue == rhsValue
            default:
                return false
            }
        case .protocol(let lhsProtocol):
            switch rhs {
            case .protocol(let rhsProtocol):
                return lhsProtocol === rhsProtocol
            default:
                return false
            }
        case .instance(of: let lhsInstance):
            switch rhs {
            case .instance(of: let rhsInstance):
                return lhsInstance === rhsInstance
            default:
                return false
            }
        case .enum(let lhsEnum):
            switch rhs {
            case .enum(let rhsEnum):
                return lhsEnum === rhsEnum
            default:
                return false
            }
        case .metaClass(let lhsMetaClass):
            switch rhs {
            case .metaClass(let rhsMetaClass):
                return lhsMetaClass === rhsMetaClass
            default:
                return false
            }
        case .metaProtocol(let lhsMetaProtocol):
            switch rhs {
            case .metaProtocol(let rhsMetaProtocol):
                return lhsMetaProtocol === rhsMetaProtocol
            default:
                return false
            }
        }
    }
    
    // checks if self fits matches type to (self can be a subclass of type)
    func conforms(to: ResolvedType) -> Bool {
        switch to {
        case .optional(let toSub):
            // if self is optional, to also has to be optional, and the contents of both optionals has to match
            switch self {
            case .optional(let selfSub):
                return selfSub.conforms(to: toSub)
            default:
                return false
            }
        case .any:
            // any can be anything except optional
            switch self {
            case .optional(_):
                return false
            default:
                return true
            }
        case .array(value: let toValue):
            // to also has to be array and value has to match
            switch self {
            case .array(let selfValue):
                return selfValue.conforms(to: toValue)
            default:
                return false
            }
        case .dictionary(key: let toKey, value: let toValue):
            // to also has to be dictionary and both key and value have to match
            switch self {
            case .dictionary(key: let selfKey, value: let selfValue):
                return selfKey.conforms(to: toKey) && selfValue.conforms(to: toValue)
            default:
                return false
            }
        case .enum(let toEnum):
            switch self {
            case .enum(let selfEnum):
                // enums can only be an exact match
                return toEnum === selfEnum
            default: break
            }
            return false
        case .protocol(let toProtocol):
            switch self {
            case .protocol(let selfProtocol):
                // if the target is a protocol and we're a protocol we either have to be the same protocol or conform to it
                if toProtocol === selfProtocol {
                    return true
                }
                
                for proto in selfProtocol.protocols {
                    if toProtocol === proto {
                        return true
                    }
                }
            case .instance(of: let selfClass):
                // if the target is a protocol and we're an instance we have to conform to it
                for proto in selfClass.protocols {
                    if toProtocol === proto {
                        return true
                    }
                }
            default: break
            }
            return false
        case .instance(of: let toClass):
            switch self {
            case .instance(of: let selfClass):
                // if the target is a class (instance) a class instance has to be used and is either an exact match or a subclass
                if selfClass === toClass {
                    return true
                }
                
                var superClass = selfClass.superClass
                while superClass != nil {
                    if superClass! === toClass {
                        return true
                    }
                    superClass = superClass!.superClass
                }
            default: break
            }
            return false
        case .metaProtocol(let toMetaProtocol):
            switch self {
            case .metaClass(of: let selfMetaClass):
                // if the target is a protocol we need to be a meta class that conforms
                for proto in selfMetaClass.protocols {
                    if toMetaProtocol === proto {
                        return true
                    }
                }
            default: break
            }
            return false
        case .metaClass(of: let toMetaClass):
            switch self {
            case .metaClass(of: let selfMetaClass):
                // if the target is a class a class has to be used and is either an exact match or a subclass
                if selfMetaClass === toMetaClass {
                    return true
                }
                
                var superClass = selfMetaClass.superClass
                while superClass != nil {
                    if superClass! === toMetaClass {
                        return true
                    }
                    superClass = superClass!.superClass
                }
            default: break
            }
            return false
        }
    }
    
}
