//
//  AbstractSyntaxTreeNodes.swift
//  Luo
//
//  Created by Oliver Cooper on 6/05/17.
//  Copyright © 2017 Oliver Cooper. All rights reserved.
//

import Foundation

indirect enum Node {
	
	case block(Node.statement)
	indirect enum statement {
		case `do`(Node.statement)
//		case set([Node.lhs], [Node.expression])
	}
//	indirect enum expression {
//		
//	}
//	case lhs

}
