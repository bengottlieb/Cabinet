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
	public var filePathBuilder = FilePathBuilder(directory: Cabinet.File.filesDirectory, extensions: ["mp3", "m4a"])
	
	public enum AfterImportAction { case none, delete, move }
	
	public var rejectedImportsDirectoryName = "Rejected Import"
	public var successfulImportsDirectoryName = "Imported"
	public var importDirectoryName = "/Import"
	public var afterImportAction = AfterImportAction.none

	public let store = Store()
	
	public func setup() {
	}
}
