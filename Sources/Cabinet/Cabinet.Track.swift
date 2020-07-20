//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/19/20.
//

import CoreData


extension Cabinet {
	@objc(CabinetTrack)
	public class Track: NSManagedObject {
		@NSManaged public dynamic var offset: Double
		@NSManaged public dynamic var duration: Double
		@NSManaged public dynamic var title: String?
		
		@NSManaged public dynamic var source: File!
		
	}
}
