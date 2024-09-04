//
//  ZAPFile.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/3/24.
//

import Foundation

enum ZAPFile {
    case url(_ fileURL: URL, serverFileTypeIdentifier: String, mimeType: MimeType? = nil)
    case data(_ fileData: Data, serverFileTypeIdentifier: String, mimeType: MimeType = .bin)
}
