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
		@NSManaged public dynamic var name: String?
		@NSManaged public dynamic var sourceID: String?
		@NSManaged public dynamic var fileType: String?
		@NSManaged public dynamic var modifiedAt: Date?
		@NSManaged public dynamic var updatedAt: Date?
		@NSManaged public dynamic var importedAt: Date?
		@NSManaged public dynamic var size: Int64
		@NSManaged public dynamic var fileURL: URL?
		@NSManaged public dynamic var dropboxHash: String?
		
		public var localURL: URL? {
			get { self.fileURL }
			set { self.fileURL = newValue }
		}
	}
}
