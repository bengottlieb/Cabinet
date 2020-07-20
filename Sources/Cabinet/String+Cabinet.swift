//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 7/19/20.
//

import Foundation

extension String {
	var extractedPertinentDuration: Double? {
		guard let last = self.deletingFileExtension.components(separatedBy: .whitespaces).last else { return nil }
		let filtered = last.filter { $0 == "." || ($0 >= "0" && $0 <= "9") }
		if filtered != last { return nil }
		
		let components = filtered.components(separatedBy: ".")
		if components.count == 2 {
			let minutes = Double(components[0]) ?? 0
			let seconds = Double(components[1]) ?? 0
			return minutes * 60 + seconds
		} else if components.count == 1 {
			return Double(components[0])
		}
 
		return nil
	}
}
