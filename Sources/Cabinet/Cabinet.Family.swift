//
//  Cabinet.Family.swift
//  
//
//  Created by Ben Gottlieb on 7/23/20.
//

import CoreData

extension Cabinet {
	@objc(CabinetFamily)
	public class Family: NSManagedObject {
		@NSManaged dynamic var tracks: NSSet?
		@NSManaged dynamic var files: NSSet?
		
		@NSManaged dynamic var name: String?
	}
}
