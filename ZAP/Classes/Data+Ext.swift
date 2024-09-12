//
//  Data+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/3/24.
//

import Foundation


extension Data {

    func convertToDictionary() throws -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String : Any]
        } catch {
            throw error
        }
    }
}
