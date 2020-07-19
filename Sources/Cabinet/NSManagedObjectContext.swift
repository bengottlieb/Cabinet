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

	func fetchFile(withDropboxHash hash: String?) -> Cabinet.File? {
		guard let hash = hash else { return nil }
		if let found: Cabinet.File = self.fetchAny(matching: NSPredicate(format: "%K == %@", #keyPath(Cabinet.File.dropboxHash), hash)) { return found }
		return nil
	}
}
