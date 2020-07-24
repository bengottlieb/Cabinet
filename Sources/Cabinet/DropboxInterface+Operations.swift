//
//  DropboxInterface+Operations.swift
//  
//
//  Created by Ben Gottlieb on 7/19/20.
//

import Foundation
import SwiftyDropbox

extension DropboxInterface {
	public typealias MoveCompletion = ((Result<String, Error>) -> Void)
	public typealias DeleteCompletion = ((Error?) -> Void)

	public func move(from src: String, batched: Bool = true, toDirectory dir: String, completion: MoveCompletion? = nil) {
		var dest = dir
		if !dest.hasSuffix("/") { dest += "/" }
		if !dest.hasPrefix("/") { dest = "/" + dest }
		let filename = src.components(separatedBy: "/").last ?? src
		dest.append(filename)
		self.move(from: src, to: dest, batched: batched, completion: completion)
	}
	
	public func move(from src: String, to dst: String, batched: Bool = true, completion: MoveCompletion? = nil) {
		if batched {
			self.queueMove(from: src, to: dst, completion: completion)
		} else {
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
	}
	
	func delete(file path: String, batched: Bool = true) {
		if batched {
			self.queueDelete(from: path)
		} else {
			client?.files.deleteV2(path: path)
		}
	}
	
	public func download(from src: String, to url: URL, completion: DeleteCompletion?) {
		client?.files.download(path: src, destination: { _, _ in url }).response { metadata, error in
			if let err = error {
				print("Error when downloading \(src): \(err)")
				completion?(DropboxError.server(err.description))
			} else {
				completion?(nil)
			}
		}
	}
}

extension DropboxInterface {
	struct BatchOp {
		
		enum Kind { case move, delete }
		let kind: Kind
		let src: String
		let dst: String?
		let completion: Any?
		
		init(deleting path: String, completion: DeleteCompletion? = nil) {
			self.kind = .delete
			self.src = path
			self.dst = nil
			self.completion = completion
		}
		
		init(moving path: String, to dest: String, completion: MoveCompletion? = nil) {
			self.kind = .move
			self.src = path
			self.dst = dest
			self.completion = completion
		}
		
		var relocationPath: Files.RelocationPath? {
			guard let dest = self.dst else { return nil }
			return Files.RelocationPath(fromPath: src, toPath: dest)
		}
		
		var deleteArg: Files.DeleteArg {
			Files.DeleteArg(path: src)
		}
	}
	
	func queueMove(from: String, to dest: String, completion: MoveCompletion? = nil) {
		self.batchQueue.async {
			self.batchedOperations.append(BatchOp(moving: from, to: dest, completion: completion))
			self.resetBatchTimer()
		}
	}
	
	func queueDelete(from: String, completion: DeleteCompletion? = nil) {
		self.batchQueue.async {
			self.batchedOperations.append(BatchOp(deleting: from, completion: completion))
			self.resetBatchTimer()
		}
	}

	func resetBatchTimer() {
		DispatchQueue.main.async {
			self.batchTimer?.invalidate()
			self.batchTimer = Timer.scheduledTimer(withTimeInterval: self.batchInterval, repeats: false) { _ in
				self.processQueuedOperations()
			}
		}
	}
	
	func processQueuedOperations() {
		self.batchQueue.async {
			let deleteThese = self.batchedOperations.filter { $0.kind == .delete }
			let moveThese = self.batchedOperations.filter { $0.kind == .move }
			
			if !deleteThese.isEmpty {
				self.client?.files.deleteBatch(entries: deleteThese.map { $0.deleteArg }).response { result, error in
					deleteThese.forEach { del in (del.completion as? DeleteCompletion)?(error as? Error) }
					
				}
			}

			if !moveThese.isEmpty {
				self.client?.files.moveBatch(entries: moveThese.compactMap { $0.relocationPath }).response { result, error in
					print("Copied: ", result?.description ?? "none")
				}
			}
		}
	}
}
