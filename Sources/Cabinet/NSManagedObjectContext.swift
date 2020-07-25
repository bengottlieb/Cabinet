//
//  NSManagedObjectContext.swift
//  
//
//  Created by Ben Gottlieb on 7/18/20.
//

import CoreData

extension NSManagedObjectContext {
	func fetchFile(withSourceID id: String) -> Cabinet.File? {
		if let found: Cabinet.File = self.fetchAny(matching: NSPredicate(format: "%K == %@", #keyPath(Cabinet.File.sourceID), id)) { return found }
		return nil
	}

	func fetchFile(withContentHash hash: String?) -> Cabinet.File? {
		guard let hash = hash else { return nil }
		if let found: Cabinet.File = self.fetchAny(matching: NSPredicate(format: "%K == %@", #keyPath(Cabinet.File.contentHash), hash)) { return found }
		return nil
	}
	
	func family(named name: String?, createIfNeeded: Bool = true) -> Cabinet.Family? {
		guard let name = name else { return nil }
		if let found: Cabinet.Family = self.fetchAny(matching: NSPredicate(format: "%K == %@", #keyPath(Cabinet.Family.name), name)) { return found }
		
		if !createIfNeeded { return nil }
		
		let family: Cabinet.Family = self.insertObject()
		family.name = name
		
		return family
	}
}
