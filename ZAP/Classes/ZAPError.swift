//
//  ZAPError.swift
//  ZAP
//
//  Created by Stephen Muscarella on 8/28/24.
//

import Foundation

// This enum contains the possible errors and brings explicit visibility into what data can be accessed from which error
public enum ZAPError<F>: Error {
    case failureError(_ error: F)
    case internalError(_ error: InternalError)
}

public struct InternalError: Error {
    var debugMsg: String
}

enum ZAPErrorMsg: String, Error {
    case malformedURL = "The URL is malformed"
    case unknown = "An unknown error occurred"
    case readDataFromFilePath = "Failed to read data from file path"
    case downloadFile = "Failed to download file at URL = "
    case urlToDataConversion = "Failed to convert URL to data for file"
}
