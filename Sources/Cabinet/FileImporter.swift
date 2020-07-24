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
	
	func move(toDirectory: DirectoryType, completion: @escaping (Error?) -> Void)
	func copy(to: URL, completion: @escaping (Error?) -> Void)
	func delete()
}

