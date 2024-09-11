//
//  NetworkingBase.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/2/24.
//

import Foundation

enum NetworkTask {
    case uploadSingleFile
    case downloadSingleFile
    case multipartFormData
    case standard
}

protocol ChainedConfiguration {
    var basicAuthCredentials: String? { get set }
    var cachePolicy: NSURLRequest.CachePolicy? { get set }
    var isMemoryCacheEnabled: Bool { get set }
    var isDiskCacheEnabled: Bool { get set }
}

public class NetworkingBase: NSObject, NetworkingRequestDelegate, NetworkingResponseDelegate, ChainedConfiguration {
    
    let cache = URLCache.shared

    var basicAuthCredentials: String?
    var cachePolicy: NSURLRequest.CachePolicy?
    var isMemoryCacheEnabled: Bool = false
    var isDiskCacheEnabled: Bool = false

    override init() {
        if URLCache.shared.memoryCapacity != ZAP.memoryCacheSize || URLCache.shared.diskCapacity != 0 {
            URLCache.shared = URLCache(memoryCapacity: ZAP.memoryCacheSize, diskCapacity: 0, directory: nil)
        }
    }
    
    func resetChainedConfigurations() {
        basicAuthCredentials = nil
        cachePolicy = nil
        isMemoryCacheEnabled = false
        isDiskCacheEnabled = false
    }
    
    func parseResponse<S: Decodable, F: Decodable>(_ response: (Data, URLResponse), requestForCaching: inout URLRequest, success: S.Type, failure: F.Type) -> Result<S, ZAPError<F>> {
        
        let urlResponse = response.1
        let responseData = response.0
        
        debugPrint(urlResponse)

        guard let httpURLResponse = urlResponse as? HTTPURLResponse, ZAP.successStatusCodes.contains(httpURLResponse.statusCode) else {
            do {
                let failure = try convertFailureDataIntoStruct(failure, responseData: responseData)
                return .failure(ZAPError.failureError(failure))
            } catch let error as InternalError {
                return .failure(ZAPError.internalError(error))
            } catch {
                return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
            }
        }
        // Memory cache
        if isMemoryCacheEnabled {
            MemoryCache().storeInMemoryCache(request: &requestForCaching, urlResponse: urlResponse, responseData: responseData)
        }
        // Disk cache
        if isDiskCacheEnabled {
            DiskCache().storeJSONData(request: requestForCaching, data: responseData)
        }

        do {
            let success = try convertSuccessDataIntoStruct(success, responseData: responseData)
            return .success(success)
        } catch let error as InternalError {
            return .failure(ZAPError.internalError(error))
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
}
