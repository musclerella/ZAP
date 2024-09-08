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
}
