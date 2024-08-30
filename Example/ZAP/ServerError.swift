//
//  ServerError.swift
//  ZAP_Example
//
//  Created by Stephen Muscarella on 8/29/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct ServerError: Decodable, Error {
    let code: Int
    let message: String
}
