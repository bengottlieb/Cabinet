//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/18/20.
//

import Foundation
import SwiftyDropbox
import Suite

extension Cabinet {
	func `import`(dropboxMetadata: [Files.Metadata]?) {
		guard let metadata = dropboxMetadata else { return }
		
		let key = UUID().uuidString
		self.store.importContext
			.sink { moc in
				for meta in metadata {
					if let fileData = meta as? Files.FileMetadata {
						if let existing = moc.fetchFile(withSourceID: fileData.id) {
							if let path = fileData.pathDisplay, let url = self.filePathBuilder.urlForFile(named: fileData.name), existing.hasChanged(given: fileData) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									if Cabinet.instance.removeImportedFilesFromSource { DropboxInterface.instance.delete(file: path) }
									moc.perform { existing.ingest(metadata: fileData, at: url) }
								}
							}
						} else {
							if let path = fileData.pathDisplay, let url = self.filePathBuilder.urlForFile(named: fileData.name) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									if Cabinet.instance.removeImportedFilesFromSource { DropboxInterface.instance.delete(file: path) }
									moc.perform { moc.insertObject(entity: Cabinet.File.self)?.ingest(metadata: fileData, at: url) }
								}
							} else if let path = meta.pathDisplay {
								DropboxInterface.instance.move(from: path, toDirectory: self.rejectedImportsDirectoryName)
							}
						}
					}
				}
				
				AnyCancellable.unsequester(key)
			}
			.sequester(key: key)
	}
}

extension Cabinet.File {
	func hasChanged(given metadata: Files.FileMetadata) -> Bool {
		return self.dropboxHash != metadata.contentHash
	}

	func ingest(metadata: Files.FileMetadata, at url: URL) {
		self.name = metadata.name
		self.modifiedAt = metadata.clientModified
		self.size = Int64(metadata.size)
		self.sourceID = metadata.id
		self.fileType = metadata.pathDisplay?.components(separatedBy: ".").last
		if self.importedAt == nil { self.importedAt = Date() }
		self.updatedAt = Date()
		
		if self.dropboxHash != metadata.contentHash {
			self.dropboxHash = metadata.contentHash
		}
		if url != self.localURL {
			if let oldURL = self.localURL { try? FileManager.default.removeItem(at: oldURL) }
			self.localURL = url
		}
		self.managedObjectContext?.saveContext(wait: false, toDisk: true, ignoreHasChanges: false)
	}
}
