//
//  HTTPHeader.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/3/24.
//

import Foundation

enum HTTPHeader {
    
    enum Key: String {
        case contentType = "Content-Type"
        case contentDisposition = "Content-Disposition"
    }
    
    enum Value {

        enum ContentType: String {
            case octetStream = "application/octet-stream"
            case multipartFormData = "multipart/form-data; boundary="
        }
    }
}
