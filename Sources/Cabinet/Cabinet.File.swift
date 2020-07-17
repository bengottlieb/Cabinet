//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation
import CoreData

extension Cabinet {
	@objc(CabinetFile)
	public class File: NSManagedObject {
		@objc public dynamic var name: String?
	}
}
