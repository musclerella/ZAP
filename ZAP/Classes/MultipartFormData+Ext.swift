//
//  MultipartFormData+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/12/24.
//

import Foundation

extension MultipartFormData {
    
    mutating func addFileToHTTPBody(boundary: String, filename: String, serverFileTypeIdentifier: String, mimeType: String) throws {
        do {
            self.append(try "--\(boundary)\r\n".encode(using: .utf8))
            self.append(try "\(HTTPHeader.Key.contentDisposition.rawValue): form-data; name=\"\(serverFileTypeIdentifier.isEmpty ? "file" : serverFileTypeIdentifier)\"; filename=\"\(filename)\"\r\n".encode(using: .utf8))
            self.append(try "\(HTTPHeader.Key.contentType.rawValue): \(mimeType)\r\n\r\n".encode(using: .utf8))
        } catch {
            throw error
        }
    }
    
    mutating func addFormDataToHTTPBody(boundary: String, formData: [String: Any]) throws {
        for (key, value) in formData {
            self.append(try "--\(boundary)\r\n".encode(using: .utf8))
            self.append(try "\(HTTPHeader.Key.contentDisposition.rawValue): form-data; name=\"\(key)\"\r\n\r\n".encode(using: .utf8))
            self.append(try "\(value)\r\n".encode(using: .utf8))
        }
    }
    
    mutating func addZAPFile(boundary: String, fileURL: URL, serverFileTypeIdentifier: String, mimeType: MimeType?) throws {
        let filename = fileURL.lastPathComponent
        let mimeType = mimeType?.rawValue ?? fileURL.extractMimeType()
        try self.addFileToHTTPBody(boundary: boundary, filename: filename, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)
        self.append(try fileURL.extractData())
        self.append(try "\r\n".encode(using: .utf8))
    }
    
    mutating func addZAPFile(boundary: String, fileData: Data, serverFileTypeIdentifier: String, mimeType: MimeType) throws {
        let filename = UUID().uuidString
        let mimeType = mimeType.rawValue
        try self.addFileToHTTPBody(boundary: boundary, filename: filename, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)
        self.append(fileData)
        self.append(try "\r\n".encode(using: .utf8))
    }
}
