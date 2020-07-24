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
	func process(importedFile: ImportableFileInfo) {
		switch afterImportAction {
		case .delete:
			importedFile.delete()
			
		case .move:
			importedFile.move(toDirectory: .imported) { _ in }
			
		case .none: break
		}
	}
	
	func `import`(files: [ImportableFileInfo]?) {
		guard let files = files else { return }
		
		let key = UUID().uuidString
		self.store.importContext
			.sink { moc in
				for fileData in files {
					if !fileData.isDirectory {
						if let existing = moc.fetchFile(withDropboxHash: fileData.sha256Hash) {
							if let path = fileData.path, let url = self.filePathBuilder.urlForFile(named: fileData.name), existing.hasChanged(given: fileData) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									if error == nil {
										self.process(importedFile: fileData)
										moc.perform { existing.ingest(file: fileData, at: url) }
									}
								}
							}
						} else {
							if let path = fileData.path, let url = self.filePathBuilder.urlForFile(named: fileData.name) {
								DropboxInterface.instance.download(from: path, to: url) { error in
									if error == nil {
										self.process(importedFile: fileData)
										moc.perform {
											let record = moc.insertObject(entity: Cabinet.File.self)
											record?.ingest(file: fileData, at: url)
										}
									}
								}
							} else if let path = fileData.path {
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
	func hasChanged(given file: ImportableFileInfo) -> Bool {
		return self.dropboxHash != file.sha256Hash
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
		self.dropboxHash = file.sha256Hash

		if url != self.localURL {
			if let oldURL = self.localURL { try? FileManager.default.removeItem(at: oldURL) }
			self.localURL = url
		}
		
		self.refreshID3Tags()

		if self.tracks.isEmpty {
			self.createTrack(named: self.title ?? file.name)
		}
		self.managedObjectContext?.saveContext(wait: false, toDisk: true, ignoreHasChanges: false)
	}
}
