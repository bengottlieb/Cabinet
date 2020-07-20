//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/18/20.
//

import Foundation
import SwiftyDropbox
import Suite
import AVFoundation

extension Cabinet {
	func processImportedFile(_ path: String) {
		switch afterImportAction {
		case .delete:
			DropboxInterface.instance.delete(file: path)
			
		case .move:
			DropboxInterface.instance.move(from: path, toDirectory: self.successfulImportsDirectoryName)
			
		case .none: break
		}
	}
	
	func `import`(dropboxMetadata: [Files.Metadata]?) {
		guard let metadata = dropboxMetadata else { return }
		
		let key = UUID().uuidString
		self.store.importContext
			.sink { moc in
				for meta in metadata {
					if let fileData = meta as? Files.FileMetadata {
						if let existing = moc.fetchFile(withDropboxHash: fileData.contentHash) {
							if let path = fileData.pathDisplay, let url = self.filePathBuilder.urlForFile(named: fileData.name), existing.hasChanged(given: fileData) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									self.processImportedFile(path)
									moc.perform { existing.ingest(metadata: fileData, at: url) }
								}
							}
						} else {
							if let path = fileData.pathDisplay, let url = self.filePathBuilder.urlForFile(named: fileData.name) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									self.processImportedFile(path)
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
		self.title = metadata.name
		self.modifiedAt = metadata.clientModified
		self.size = Int64(metadata.size)
		self.sourceID = metadata.id
		self.fileType = metadata.pathDisplay?.components(separatedBy: ".").last
		if self.importedAt == nil { self.importedAt = Date() }
		self.updatedAt = Date()
		self.pertinentDuration = metadata.name.extractedPertinentDuration ?? 0.0
		self.duration = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
		self.dropboxHash = metadata.contentHash

		if url != self.localURL {
			if let oldURL = self.localURL { try? FileManager.default.removeItem(at: oldURL) }
			self.localURL = url
		}
		
		self.refreshID3Tags()

		if self.tracks.isEmpty {
			self.createTrack(named: self.title ?? metadata.name)
		}
		self.managedObjectContext?.saveContext(wait: false, toDisk: true, ignoreHasChanges: false)
	}
}
