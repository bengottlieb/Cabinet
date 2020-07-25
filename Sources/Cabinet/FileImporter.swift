//
//  FileImporter.swift
//  
//
//  Created by Ben Gottlieb on 7/23/20.
//

import Foundation

public protocol FileImporter {
	associatedtype FileInfo: ImportableFileInfo
	
	func checkForNewFiles(in path: String, completion: @escaping (Result<[FileInfo], Error>) -> Void)
}

extension FileImporter {
	public func importFiles(from path: String) {
		Cabinet.instance.importDirectoryName = path
		self.checkForNewFiles(in: path) { results in
			switch results {
			case .success(let files): Cabinet.instance.import(files: files)
			case .failure(let error): print("Error when importing from \(path): \(error)")
			}
		}
	}	
}

public enum DirectoryType { case imported, rejected }

public protocol ImportableFileInfo {
	var isDirectory: Bool { get }
	var name: String { get }
	var sha256Hash: String? { get }
	var path: String? { get }
	var modifiedAt: Date? { get }
	var fileSize: Int64 { get }
	var fileID: String? { get }
	
	func move(toDirectory: DirectoryType, completion: ((Error?) -> Void)?)
	func copy(to: URL, completion: ((Error?) -> Void)?)
	func delete()
}

extension ImportableFileInfo {
	var localURL: URL? {
		Cabinet.instance.filePathBuilder.urlForFile(named: self.name)
	}
	
	var parentDirectoryName: String? {
		guard var path = self.path?.components(separatedBy: "/") else { return nil }
		
		path.remove("")
		if path.first == Cabinet.instance.importDirectoryName { path.removeFirst() }
		if path.last == self.name { path.removeLast() }
		
		return path.first?.isEmpty != true ? path.first : nil
	}
}
