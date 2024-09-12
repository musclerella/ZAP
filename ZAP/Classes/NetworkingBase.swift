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

    func parseResponse<S: Decodable, F: Decodable>(_ response: (Data, URLResponse), requestForCaching: inout URLRequest, success: S.Type, failure: F.Type) throws -> S {
        
        let urlResponse = response.1
        let responseData = response.0
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
        
        debugPrint(urlResponse)

        guard ZAP.successStatusCodes.contains(statusCode) else {
            do {
                let serverError = try deserializeServerError(failure, responseData: responseData)
                throw ZAPError(statusCode: statusCode, serverError: serverError, internalErrorMsg: nil)
            } catch let error as InternalError {
                throw ZAPError<F>(statusCode: statusCode, serverError: nil, internalErrorMsg: error.internalErrorMessage)
            } catch {
                throw ZAPError<F>(statusCode: statusCode, serverError: nil, internalErrorMsg: error.localizedDescription)
            }
        }

        if isMemoryCacheEnabled {
            MemoryCache().storeDataInCache(request: &requestForCaching, urlResponse: urlResponse, responseData: responseData)
        }
        if isDiskCacheEnabled {
            DiskCache().storeJSONData(request: requestForCaching, data: responseData)
        }

        do {
            return try deserializeSuccess(success, responseData: responseData)
        } catch let error as InternalError {
            throw ZAPError<F>(statusCode: statusCode, serverError: nil, internalErrorMsg: error.internalErrorMessage)
        } catch {
            throw ZAPError<F>(statusCode: statusCode, serverError: nil, internalErrorMsg: error.localizedDescription)
        }
    }
}
