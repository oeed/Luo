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
    
    // check if the both types are an exact match (for protocols)
    static func ==(_ lhs: ResolvedType, _ rhs: ResolvedType) {
        
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
