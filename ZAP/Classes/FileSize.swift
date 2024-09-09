//
//  FileSize.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/8/24.
//

import Foundation

typealias Megabytes = Double

func getFileSizeInMegabytes(at fileURL: URL) -> Megabytes {
    do {
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File does not exist at path: \(fileURL.path)")
            return 0
        }
        // Get the file attributes for the file at the given URL
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        // Retrieve the file size attribute from the attributes dictionary
        if let fileSize = attributes[.size] as? UInt64 {
            return bytesToMegabytes(fileSize)
        } else {
            debugPrint("File size attribute is unavailable or invalid.")
            return 0
        }
    } catch {
        debugPrint("Error retrieving attributes of file: \(error)")
        return 0
    }
}

func bytesToMegabytes(_ bytes: UInt64) -> Double {
    return Double(bytes) / 1_048_576.0  // 1 MB = 1024 * 1024 bytes
}
