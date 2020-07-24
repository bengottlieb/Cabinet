//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation
import CoreData
import Suite
import ID3TagEditor

extension Cabinet {
	@objc(CabinetFile)
	public class File: NSManagedObject {
		@NSManaged public dynamic var title: String?
		@NSManaged public dynamic var sourceID: String?
		@NSManaged public dynamic var fileType: String?
		@NSManaged public dynamic var modifiedAt: Date?
		@NSManaged public dynamic var updatedAt: Date?
		@NSManaged public dynamic var importedAt: Date?
		@NSManaged public dynamic var size: Int64
		@NSManaged public dynamic var filePath: String?
		@NSManaged public dynamic var dropboxHash: String?

		@NSManaged public dynamic var album: String?
		@NSManaged public dynamic var artist: String?
		@NSManaged public dynamic var composer: String?
		@NSManaged public dynamic var copyright: String?
		@NSManaged public dynamic var genre: String?
		@NSManaged public dynamic var tags: String?
		@NSManaged public dynamic var bpm: Int
		@NSManaged public dynamic var bitrate: Int
		@NSManaged public dynamic var duration: Double
		@NSManaged public dynamic var declaredDuration: Double
		@NSManaged public dynamic var trackNumber: Int
		@NSManaged public dynamic var year: Int
		
		@NSManaged public dynamic var tracks: Set<Cabinet.Track>

		static let filesDirectory = FileManager.libraryDirectory.appendingPathComponent("CabinetFiles", isDirectory: true)
		
		public var localURL: URL? {
			get { self.filePath == nil ? nil : Self.filesDirectory.appendingPathComponent(self.filePath!) }
			set { self.filePath = newValue - Self.filesDirectory }
		}
		
		public func refreshID3Tags() {
			guard let url = self.localURL else { return }
			let editor = ID3TagEditor()
			do {
				let tags = try editor.read(from: url.path)
				
				if let title = tags?.frames[.Title] as? ID3FrameWithStringContent { self.title = title.content }
				if let album = tags?.frames[.Album] as? ID3FrameWithStringContent { self.album = album.content }
				if let composer = tags?.frames[.Composer] as? ID3FrameWithStringContent { self.composer = composer.content }
				if let copyright = tags?.frames[.Copyright] as? ID3FrameWithStringContent { self.copyright = copyright.content }
				if let genre = tags?.frames[.Genre] as? ID3FrameWithStringContent { self.genre = genre.content }
			} catch {
				print("Problem reading ID Tags from \(url.path): \(error)")
			}
		}
		
		@discardableResult func createTrack(named name: String) -> Cabinet.Track? {
			guard let moc = self.moc else { return nil }
			
			let track: Cabinet.Track = moc.insertObject()
			track.source = self
			track.title = name
			return track
		}
	}
}

public extension URL {
	static func -(lhs: URL?, rhs: URL) -> String? {
		guard let lhs = lhs else { return nil }
		let lhString = lhs.path
		let rhString = rhs.path
		
		if lhString.hasPrefix(rhString) {
			let index = lhString.index(lhString.startIndex, offsetBy: rhString.count)
			return String(lhString[index...])
		}
		return lhString
	}
}
