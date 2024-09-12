//
//  URL+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/12/24.
//

import Foundation
import UniformTypeIdentifiers

extension URL {

    func extractData() throws -> Data {
        do {
            return try Data(contentsOf: self)
        } catch {
            throw error
        }
    }
    
    func extractMimeType() -> String {
        let pathExtension = self.pathExtension
        if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimeType
        } else if let mimeType = FileExtensionMap.getMimeTypeFromExtension(pathExtension) {
            return mimeType
        }
        return MimeType.bin.rawValue
    }
}
