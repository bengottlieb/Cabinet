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
		@NSManaged public dynamic var colorHex: String?
		@NSManaged public dynamic var relativeVolume: Double
		
		
		@NSManaged public dynamic var rate: Double
		@NSManaged public dynamic var pan: Double

		@NSManaged public dynamic var fadeIn: Double
		@NSManaged public dynamic var fadeOut: Double

		@NSManaged public dynamic var preWait: Double
		@NSManaged public dynamic var postWait: Double

		@NSManaged public dynamic var weighting: Double
		@NSManaged public dynamic var notes: String?

		@NSManaged public dynamic var overrideFlags: Int64

		@NSManaged public dynamic var source: File!
		@NSManaged public dynamic var family: Family?
		
		public var familyName: String? { family?.name }

	}
}
