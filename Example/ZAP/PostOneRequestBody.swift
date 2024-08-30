//
//  RequestBody.swift
//  ZAP_Example
//
//  Created by Stephen Muscarella on 8/28/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct PostOneRequestBody: Encodable {
    var name: String
    var age: Int
}
