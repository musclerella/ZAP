//
//  FileSize.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/8/24.
//

import Foundation

public typealias Megabytes = Int

func getFileSizeInMegabytes(at fileURL: URL) -> (Megabytes?, InternalError?) {
    do {
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return (nil, InternalError(debugMsg: "File does not exist at path: \(fileURL.path)"))
        }
        // Get the file attributes for the file at the given URL
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        // Retrieve the file size attribute from the attributes dictionary
        if let fileSize = attributes[.size] as? UInt64 {
            return (bytesToMegabytes(fileSize), nil)
        } else {
            return (nil, InternalError(debugMsg: "File size attribute is unavailable or invalid."))
        }
    } catch {
        return (nil, InternalError(debugMsg: "Error retrieving attributes of file: \(error.localizedDescription)"))
    }
}

func bytesToMegabytes(_ bytes: UInt64) -> Megabytes {
    return Megabytes((Double(bytes) / 1_048_576.0).rounded(.towardZero))  // 1 MB = 1024 * 1024 bytes
}
