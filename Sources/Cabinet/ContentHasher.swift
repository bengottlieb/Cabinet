//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/23/20.
//

import Foundation
import CryptoKit

public struct ContentHasher {
	public static func hash(file url: URL) -> String? {
		guard let data = try? Data(contentsOf: url) else { return nil }
		let size = data.count
		var offset = 0
		let chunkSize = 4 * 1024 * 1024
		var concatHash = Data()
		
		while offset < size {
			let chunk = data[offset..<(offset + min(chunkSize, size - offset))]
			concatHash += SHA256.hash(data: chunk)
			offset += chunkSize
		}
		
		return SHA256.hash(data: concatHash).toString
	}
}

extension SHA256.Digest {
	var toString: String { self.compactMap { String(format: "%02x", $0) }.joined() }
}
