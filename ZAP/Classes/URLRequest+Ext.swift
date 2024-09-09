//
//  URLRequest+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/7/24.
//

import Foundation

extension URLRequest {
    
    mutating func addBasicAuthentication(credential: String?) {
        guard let credential else { return }
        var headers = self.allHTTPHeaderFields ?? [String: String]()
        headers[HTTPHeader.Key.authorization.rawValue] = HTTPHeader.Value.Authorization.basic.rawValue.appending(credential)
        self.allHTTPHeaderFields = headers
    }
    
    mutating func removeMultipartFormDataBoundaryFromHeaders() {
        guard var headers = self.allHTTPHeaderFields else { return }
        if let contentTypeValue = headers[HTTPHeader.Key.contentType.rawValue], contentTypeValue.hasPrefix(HTTPHeader.Value.ContentType.multipartFormData.rawValue) {
            headers[HTTPHeader.Key.contentType.rawValue] = HTTPHeader.Value.ContentType.multipartFormData.rawValue
        }
        self.allHTTPHeaderFields = headers
    }
    
    func removeAndReturnMultipartFormDataBoundaryFromHeaders() -> URLRequest {
        var headers = self.allHTTPHeaderFields
        if let contentTypeValue = headers?[HTTPHeader.Key.contentType.rawValue], contentTypeValue.hasPrefix(HTTPHeader.Value.ContentType.multipartFormData.rawValue) {
            headers?[HTTPHeader.Key.contentType.rawValue] = HTTPHeader.Value.ContentType.multipartFormData.rawValue
        }
        var request = self
        request.allHTTPHeaderFields = headers
        return request
    }
}
