//
//  Cabinet.Store+Importing.swift
//  
//
//  Created by Ben Gottlieb on 7/18/20.
//

import Foundation
import Suite
import AVFoundation

extension Cabinet {
	func process(importedFile: ImportableFileInfo) {
		switch afterImportAction {
		case .delete:
			importedFile.delete()
			
		case .move:
			importedFile.move(toDirectory: .imported, completion: nil)
			
		case .none: break
		}
	}
	
	func `import`(files: [ImportableFileInfo]?, in parent: ImportableFileInfo? = nil) {
		guard let files = files else { return }
		
		let key = UUID().uuidString
		self.store.importContext
			.sink { moc in
				for file in files {
					if !file.isDirectory {
						if let existing = moc.fetchFile(withContentHash: file.sha256Hash) {
							if existing.hasChanged(given: file), let url = file.localURL {
								file.copy(to: url) { error in
									if error == nil {
										self.process(importedFile: file)
										moc.perform { existing.ingest(file: file, at: url) }
									}
								}
							}
						} else {
							if let url = file.localURL {
								file.copy(to: url) { error in
									if error == nil {
										moc.perform {
											self.process(importedFile: file)
											let record = moc.insertObject(entity: Cabinet.File.self)
											record?.ingest(file: file, at: url)
										}
									}
								}
							} else {
								file.move(toDirectory: .rejected, completion: nil)
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
	func hasChanged(given file: ImportableFileInfo) -> Bool {
		return self.contentHash != file.sha256Hash
	}

	func ingest(file: ImportableFileInfo, at url: URL) {
		self.title = file.name
		self.modifiedAt = file.modifiedAt
		self.size = file.fileSize
		self.sourceID = file.fileID
		self.fileType = file.path?.components(separatedBy: ".").last
		if self.importedAt == nil { self.importedAt = Date() }
		self.updatedAt = Date()
		self.declaredDuration = file.name.extractedDeclaredDuration ?? 0.0
		#if !targetEnvironment(simulator)
			self.duration = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
		#endif
		self.contentHash = file.sha256Hash

		if url != self.localURL {
			if let oldURL = self.localURL { try? FileManager.default.removeItem(at: oldURL) }
			self.localURL = url
		}
		
		if let family = self.managedObjectContext?.family(named: file.parentDirectoryName) {
			self.family = family
		}
		
		self.refreshID3Tags()

		if self.tracks.count == 0 {
			self.createTrack(named: self.title ?? file.name)
		}
		self.managedObjectContext?.saveContext(wait: false, toDisk: true, ignoreHasChanges: false)
	}
}
