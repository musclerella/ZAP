//
//  ZAPError.swift
//  ZAP
//
//  Created by Stephen Muscarella on 8/28/24.
//

import Foundation

public struct ZAPError<F>: Error {
    public let statusCode: Int
    public let serverError: F?
    public let internalErrorMsg: String?
    init(statusCode: Int = 0, serverError: F?, internalErrorMsg: String?) {
        self.statusCode = statusCode
        self.serverError = serverError
        self.internalErrorMsg = internalErrorMsg
    }
}

struct InternalError: Error {
    let internalErrorMessage: String
    init(_ message: String) {
        self.internalErrorMessage = message
    }
}

enum ZAPErrorMsg: String {
    case malformedURL = "The URL is malformed"
    case unknown = "An unknown error occurred"
    case readDataFromFilePath = "Failed to read data from file path"
    case downloadFile = "Failed to download file at URL = "
    case urlToDataConversion = "Failed to convert URL to data for file"
    case stringEncodingError = "Failed to encode string "
}
