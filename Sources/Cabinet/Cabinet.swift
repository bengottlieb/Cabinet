//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation

public class Cabinet {
	public static let instance = Cabinet()
	
	public let store = Store()
	
	public func setup() {
	}
}
