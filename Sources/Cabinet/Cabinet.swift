//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation
import Suite

public class Cabinet {
	public static let instance = Cabinet()
	public var filePathBuilder = FilePathBuilder(directory: FileManager.documentsDirectory.appendingPathComponent("Imported Music"), extensions: ["mp3", "m4a"])
	
	public var rejectedImportsDirectoryName = "Rejected Import"
	public var successfulImportsDirectoryName = "Imported"
	public var removeImportedFilesFromSource = true

	public let store = Store()
	
	public func setup() {
	}
}
