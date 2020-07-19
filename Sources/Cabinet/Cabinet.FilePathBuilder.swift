//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/18/20.
//

import Foundation
import Studio

extension Cabinet {
	public struct FilePathBuilder {
		let extensions: [String]
		let url: URL
		
		init(directory: URL, extensions: [String]) {
			self.url = directory
			self.extensions = extensions.map { $0.lowercased() }
			
			try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		}
		
		func urlForFile(named name: String) -> URL? {
			let ext = name.fileExtension ?? ""
			if !self.extensions.contains(ext.lowercased()) { return nil }
			let mgr = FileManager.default
			var count = 0
			
			let nameOnly = name.deletingFileExtension 
			let baseURL = self.url
			
			while true {
				let url = baseURL.appendingPathComponent((count == 0) ? "\(nameOnly).\(ext)" : "\(nameOnly) \(count + 1).\(ext)")
				if !mgr.fileExists(at: url) { return url }
				count += 1
			}
			
		}
	}
}


