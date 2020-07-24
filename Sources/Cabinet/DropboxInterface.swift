//
//  DropboxInterface.swift
//
//
//  Created by Ben Gottlieb on 7/18/20.
//

import Foundation
import SwiftyDropbox
import UIKit
import Suite
import SwiftUI


// Dropbox app page: https://www.dropbox.com/developers/apps/info/3jzy836caceuxw4

public class DropboxInterface: ObservableObject, FileImporter {
	public static let instance = DropboxInterface()
	
	public typealias FileInfo = Files.Metadata
	
	public struct Notifications {
		public static let didAuthorize = Notification.Name(rawValue: "DropboxInterface.didAuthorize")
	}
	
	public enum DropboxError: Error { case notSetup, badImage, server(String), noResponse }
	
	@Published public var isAuthorized = false

	var client: DropboxClient? { DropboxClientsManager.authorizedClient }
	weak var batchTimer: Timer?
	var batchInterval = 2.0
	var batchedOperations: [BatchOp] = []
	let batchQueue = DispatchQueue(label: "dropbox-batch", qos: .userInitiated)
	
	
	public func setup(withAPIKey apiKey: String = "3jzy836caceuxw4") {
		DropboxClientsManager.setupWithAppKey(apiKey)
		self.isAuthorized = DropboxClientsManager.authorizedClient != nil
		NotificationCenter.default.publisher(for: Notifications.didAuthorize)
			.map { _ in true }
			.assign(to: \.isAuthorized, on: self)
			.sequester()
	}
	
	public func disconnect() {
		DropboxClientsManager.unlinkClients()
		self.isAuthorized = false
	}
	
	public func checkForNewFiles(in path: String = Cabinet.instance.importDirectoryName, completion: @escaping (Result<[Files.Metadata], Error>) -> Void) {
		_ = client?.files.listFolder(path: path.prefixedBySlashIfRequired).response { response, error in
			if let entries = response?.entries {
				completion(.success(entries))
			}
		}
	}
	
	public func authorize(from controller: UIViewController?) {
		guard let controller = controller else { return }
		
		DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: controller) {
			UIApplication.shared.open($0, options: [:])
		}
	}
	
	public func handle(url: URL) {
		DropboxClientsManager.handleRedirectURL(url) { authResult in
			switch authResult {
			case .success:
				self.isAuthorized = true
				
			case .cancel: break

			case .error(_, let description):
				print("Dropbox Error: \(description ?? "unknown error")")
				
			default:
				print("Uh oh, dropbox broke")
			}
		}
	}
}

public struct DropboxAuthorizationButton: View {
	@ObservedObject var dropbox = DropboxInterface.instance
	
	public init() { }
	
	public var body: some View {
		Button(action: {
			if self.dropbox.isAuthorized {
				self.dropbox.disconnect()
			} else {
				self.dropbox.authorize(from: self.enclosingRootViewController)
			}
		}) {
			if dropbox.isAuthorized {
				Text("Disconnect")
			} else {
				Text("Authorize")
			}
		}
	}
}


extension Files.Metadata: ImportableFileInfo {
	public var isDirectory: Bool { !(self is Files.FileMetadata) }
	public var sha256Hash: String? { (self as? Files.FileMetadata)?.contentHash }
	public var path: String? { (self as? Files.FileMetadata)?.pathDisplay }
	public var fileID: String? { (self as? Files.FileMetadata)?.id }
	public var modifiedAt: Date? { (self as? Files.FileMetadata)?.clientModified }
	public var fileSize: Int64 { Int64((self as? Files.FileMetadata)?.size ?? 0) }

	public func move(toDirectory: DirectoryType, completion: @escaping (Error?) -> Void) {
		guard let path = self.pathDisplay else { return }
		
		switch toDirectory {
		case .imported:
			DropboxInterface.instance.move(from: path, toDirectory: Cabinet.instance.successfulImportsDirectoryName)
			
		case .rejected:
			DropboxInterface.instance.move(from: path, toDirectory: Cabinet.instance.rejectedImportsDirectoryName)
		}
	}
	
	public func copy(to url: URL, completion: @escaping (Error?) -> Void) {
		if let path = self.pathDisplay {
			DropboxInterface.instance.download(from: path, to: url) { error in
				completion(error)
			}
		} else {
			completion(nil)
		}
	}
	
	public func delete() {
		guard let path = self.pathDisplay else { return }
		DropboxInterface.instance.delete(file: path)
	}
}
