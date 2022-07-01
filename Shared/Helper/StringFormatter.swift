//
//  StringFormatter.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 01.07.22.
//

import Foundation

extension String {
    var cleanedFileName: String {
        let fileNameChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return self.filter { fileNameChars.contains($0) }
    }
}
