//
//  ICloudDriveInterface.swift
//  
//
//  Created by Ben Gottlieb on 7/23/20.
//

import Foundation

public class ICloudDriveInterface: ObservableObject, FileImporter {
	public static let instance = ICloudDriveInterface()
	
	let baseURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
	lazy var documents = ICloudDriveInterface.instance.baseURL?.appendingPathComponent("Documents")
	lazy var successfulImportDirectory = ICloudDriveInterface.instance.documents?.appendingPathComponent(Cabinet.instance.successfulImportsDirectoryName)
	lazy var rejectedImportDirectory = ICloudDriveInterface.instance.documents?.appendingPathComponent(Cabinet.instance.rejectedImportsDirectoryName)

	
	public func setup() {
		if let dir = successfulImportDirectory { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil) }
		if let dir = rejectedImportDirectory { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil) }
	}
	
	public func checkForNewFiles(in path: String = Cabinet.instance.importDirectoryName, completion: @escaping (Result<[FileInfo], Error>) -> Void) {
		guard let dir = ICloudDriveInterface.instance.documents?.appendingPathComponent(path) else {
			return
		}
		
		try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
		
		do {
			let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
			
			completion(.success(urls.map { FileInfo(url: $0) }))
		} catch {
			completion(.failure(error))
		}
		
	}
	
	public struct FileInfo: ImportableFileInfo {
		let url: URL
		
		public var isDirectory: Bool { FileManager.default.fileNotDirectoryExists(at: url) }
		public var name: String { url.deletingPathExtension().lastPathComponent }
		public var sha256Hash: String? { ContentHasher.hash(file: url) }
		public var path: String? { url.path }
		public var modifiedAt: Date? { (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date }
		public var fileSize: Int64 { (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64 ?? 0 }
		public var fileID: String? { sha256Hash }

		public func move(toDirectory: DirectoryType, completion: ((Error?) -> Void)?) {
			do {
				switch toDirectory {
				case .imported:
					if let dir = ICloudDriveInterface.instance.successfulImportDirectory {
						let dest = dir.appendingPathComponent(url.lastPathComponent)
						try FileManager.default.moveItem(at: url, to: dest)
					}

				case .rejected:
					if let dir = ICloudDriveInterface.instance.rejectedImportDirectory {
						let dest = dir.appendingPathComponent(url.lastPathComponent)
						try FileManager.default.moveItem(at: url, to: dest)
					}
				}
				
				completion?(nil)
			} catch {
				completion?(error)
			}
		}
		
		public func copy(to: URL, completion: ((Error?) -> Void)?) {
			do {
				try FileManager.default.copyItem(at: url, to: to)
				completion?(nil)
			} catch {
				completion?(error)
			}
		}
		
		public func delete() {
			try? FileManager.default.removeItem(at: url)
		}
	}
}
