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

public class DropboxInterface: ObservableObject {
	public static let instance = DropboxInterface()
	
	public struct Notifications {
		public static let didAuthorize = Notification.Name(rawValue: "DropboxInterface.didAuthorize")
	}
	
	public enum DropboxError: Error { case notSetup, badImage, server(String), noResponse }
	
	@Published public var isAuthorized = false

	
	private var client: DropboxClient? { DropboxClientsManager.authorizedClient }
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
	
	public func checkForNewFiles(in path: String = "") {
		_ = client?.files.listFolder(path: "").response { response, error in
			Cabinet.instance.import(dropboxMetadata: response?.entries)
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

extension DropboxInterface {
	public func move(from src: String, toDirectory dir: String, completion: ((Result<String, Error>) -> Void)? = nil) {
		var dest = dir
		if !dest.hasSuffix("/") { dest += "/" }
		if !dest.hasPrefix("/") { dest = "/" + dest }
		let filename = src.components(separatedBy: "/").last ?? src
		dest.append(filename)
		self.move(from: src, to: dest, completion: completion)
	}
	
	public func move(from src: String, to dst: String, completion: ((Result<String, Error>) -> Void)? = nil) {
		client?.files.moveV2(fromPath: src, toPath: dst, autorename: true).response { response, error in
			if let err = error {
				completion?(.failure(DropboxError.server(err.description)))
			} else if let name = response?.metadata.name {
				completion?(.success(name))
			} else {
				completion?(.failure(DropboxError.noResponse))
			}
		}
	}
	
	func delete(file path: String) {
		client?.files.deleteV2(path: path)
	}
	
	public func download(from src: String, to url: URL, completion: ((Error?) -> Void)?) {
		client?.files.download(path: src, destination: { _, _ in url }).response { metadata, error in
			if let err = error {
				print("Error when downloading \(src): \(err)")
			} else {
				completion?(nil)
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
