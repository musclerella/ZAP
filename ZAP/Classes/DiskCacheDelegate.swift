//
//  DiskCacheDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/12/24.
//

import Foundation

protocol DiskCacheDelegate: ChainedConfiguration {
    func fetchFromDiskCache<S: Decodable>(url: String, success: S.Type) -> S?
    func fetchFromDiskCache(url: String) -> Data?
}

extension DiskCacheDelegate {
    
    func fetchFromDiskCache(url: String) -> Data? {
        if isDiskCacheEnabled {
            return DiskCache().cachedDataAt(url: url)
        }
        return nil
    }
    
    func fetchFromDiskCache<S: Decodable>(url: String, success: S.Type) -> S? {
        if isDiskCacheEnabled {
            return DiskCache().cachedSuccessAt(url: url, success: success)
        }
        return nil
    }
}
