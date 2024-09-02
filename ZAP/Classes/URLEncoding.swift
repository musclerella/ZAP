//
//  URLEncoding.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation

extension URLQueryItem {

    func percentEncoded() -> URLQueryItem {
        /// addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) encode parameters following RFC 3986
        /// which we need to encode other special characters correctly.
        /// We then also encode "+" sign with its HTTP equivalent

        var newQueryItem = self
        newQueryItem.value = value?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "&", with: "%26")
        
        return newQueryItem
    }
}

extension Array where Element == URLQueryItem {

    func percentEncoded() -> Array<Element> {
        return map { $0.percentEncoded() }
    }
}
