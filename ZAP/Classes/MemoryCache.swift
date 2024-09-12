//
//  MemoryCache.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

class MemoryCache: NetworkingResponseDelegate {    
    
    let cache: URLCache = URLCache.shared
    
    func retrieveDataFor(request: URLRequest) -> Data? {
        return cache.cachedResponse(for: request)?.data
    }
    
    func retrieveValueFor<S: Decodable>(request: URLRequest, success: S.Type) -> S? {
        let cacheableRequest = request.removeAndReturnMultipartFormDataBoundaryFromHeaders()
        if let cachedResponseData = cache.cachedResponse(for: cacheableRequest)?.data {
            do {
                return try deserializeSuccess(success, responseData: cachedResponseData)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }
    
    func storeData(request: inout URLRequest, urlResponse: URLResponse, responseData: Data) {
        let cachedResponse = CachedURLResponse(response: urlResponse, data: responseData)
        request.removeMultipartFormDataBoundaryFromHeaders()
        cache.storeCachedResponse(cachedResponse, for: request)
    }
}
