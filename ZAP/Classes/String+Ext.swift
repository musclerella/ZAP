//
//  String+Ext.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/12/24.
//

import Foundation

extension String {
    
    func encode(using encoding: String.Encoding, allowLossyConversion: Bool = false) throws -> Data {
        guard let stringData = self.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
            throw InternalError(ZAPErrorMsg.stringEncodingError.rawValue.appending(self))
        }
        return stringData
    }
}
