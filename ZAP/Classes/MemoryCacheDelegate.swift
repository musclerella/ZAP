//
//  CacheDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

protocol MemoryCacheDelegate: ChainedConfiguration {
    func fetchFromMemoryCache<S: Decodable>(request: URLRequest, success: S.Type) -> S?
    func fetchFromMemoryCache(request: URLRequest) -> Data?
}

extension MemoryCacheDelegate {
    
    func fetchFromMemoryCache(request: URLRequest) -> Data? {
        if isMemoryCacheEnabled {
            return MemoryCache().cachedDataFor(request: request)
        }
        return nil
    }
    
    func fetchFromMemoryCache<S: Decodable>(request: URLRequest, success: S.Type) -> S? {
        if isMemoryCacheEnabled {
            return MemoryCache().cachedValueFor(request: request, success: success)
        }
        return nil
    }
    
}
