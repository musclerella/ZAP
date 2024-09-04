//
//  Data+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/3/24.
//

import Foundation

extension Data {

    func convertToDictionary() -> ([String: Any]?, InternalError?)  {

        do {
            let jsonDict = try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
            return (jsonDict, nil)
        } catch {
            return (nil, InternalError(debugMsg: error.localizedDescription))
        }
    }
}
