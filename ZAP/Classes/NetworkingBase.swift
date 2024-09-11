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

public class NetworkingBase: NSObject, ChainedConfiguration {
    
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
    
    //MARK: Common Methods
    func configureURLSession(delegate: URLSessionDelegate) -> URLSession {

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = isMemoryCacheEnabled ? URLCache.shared : nil
        configuration.requestCachePolicy = cachePolicy ?? ZAP.defaultCachePolicy

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    func resetChainedConfigurations() {
        // Clears localized chained configurations for a request. Applys to singleton based implementations so subsequent requests do not pick up previously used configurations
        // This should NOT be needed for instance based implementations since a different ZAP instance is created for every single request
        basicAuthCredentials = nil
        cachePolicy = nil
        isMemoryCacheEnabled = false
        isDiskCacheEnabled = false
    }
    
    func retrieveFromMemoryCache<S: Decodable>(request: URLRequest, success: S.Type) -> S? {
        let cacheableRequest = request.removeAndReturnMultipartFormDataBoundaryFromHeaders()
        if let cachedResponseData = cache.cachedResponse(for: cacheableRequest)?.data {
            let success = handleSuccess(success, responseData: cachedResponseData)
            if let cachedValue = success.0 {
                return cachedValue
            }
        }
        return nil
    }
    
    func storeInMemoryCache(request: inout URLRequest, urlResponse: URLResponse, responseData: Data) {
        let cachedResponse = CachedURLResponse(response: urlResponse, data: responseData)
        request.removeMultipartFormDataBoundaryFromHeaders()
        cache.storeCachedResponse(cachedResponse, for: request)
    }
    
    func buildURL(url: String, queryItems: [URLQueryItem]? = nil) -> (URL?, InternalError?) {
        if let queryItems, var urlComponents = URLComponents(string: url) {
            urlComponents.percentEncodedQueryItems = queryItems.percentEncoded()
            return (urlComponents.url, nil)
        } else if let url = URL(string: url) {
            return (url, nil)
        } else {
            let internalError = InternalError(debugMsg: ZAPErrorMsg.malformedURL.rawValue)
            return (nil, internalError)
        }
    }

    func buildRequest(task: NetworkTask, method: HTTPMethod, url: URL, body: Encodable? = nil, headers: [String: String]? = nil, boundary: String = "") -> (URLRequest?, InternalError?) {
        do {
            var httpBody: Data?
            if let body {
                httpBody = try JSONEncoder().encode(body)
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue.uppercased()
            urlRequest.allHTTPHeaderFields = headers
            urlRequest.httpBody = httpBody
            urlRequest.addBasicAuthentication(credential: basicAuthCredentials)
            urlRequest = addDefaultHeadersIfApplicable(for: task, urlRequest: &urlRequest, boundary: boundary)
            
            return (urlRequest, nil)
            
        } catch let error as EncodingError {
            let errMsg = extractEncodingErrorMsg(error)
            let internalError = InternalError(debugMsg: errMsg)
            return (nil, internalError)
        } catch {
            let internalError = InternalError(debugMsg: error.localizedDescription)
            return (nil, internalError)
        }
    }
    
    func addDefaultHeadersIfApplicable(for task: NetworkTask, urlRequest: inout URLRequest, boundary: String = "") -> URLRequest {
        switch task {
        case .uploadSingleFile:
            if urlRequest.allHTTPHeaderFields?[HTTPHeader.Key.contentType.rawValue] == nil {
                urlRequest.addValue(HTTPHeader.Value.ContentType.octetStream.rawValue, forHTTPHeaderField: HTTPHeader.Key.contentType.rawValue)
            }
        case .multipartFormData:
            urlRequest.addValue(HTTPHeader.Value.ContentType.multipartFormData.rawValue.appending(boundary), forHTTPHeaderField: HTTPHeader.Key.contentType.rawValue)
        case .standard:
            break
        case .downloadSingleFile:
            break
        }
        return urlRequest
    }
    
    func parseResponse<S: Decodable, F: Decodable>(_ response: (Data, URLResponse), requestForCaching: inout URLRequest, success: S.Type, failure: F.Type) -> Result<S, ZAPError<F>> {
        
        let urlResponse = response.1
        let responseData = response.0
        
        debugPrint(urlResponse)

        guard let httpURLResponse = urlResponse as? HTTPURLResponse, httpURLResponse.statusCode == 200 else {
            let failureResult = handleFailure(failure, responseData: responseData)
            if let failure = failureResult as? ZAPError<F> {
                return .failure(failure)
            } else if case .internalError(let internalError) = failureResult {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while decoding the failure.")))
            }
        }

        let successResult = handleSuccess(success, responseData: responseData)
        if let success = successResult.0 {
            if isMemoryCacheEnabled {
                storeInMemoryCache(request: &requestForCaching, urlResponse: urlResponse, responseData: responseData)
            }
            if isDiskCacheEnabled {
                if let cacheableURL = requestForCaching.url?.absoluteString {
                    do {
                        try DiskCache().storeJSONData(responseData, for: cacheableURL)
                    } catch {
                        return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
                    }
                }
            }
            return .success(success)
        } else if let internalError = successResult.1 {
            return .failure(ZAPError.internalError(internalError))
        } else {
            return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while decoding the success.")))
        }
    }
    
    func handleSuccess<S: Decodable>(_ success: S.Type, responseData: Data) -> (S?, InternalError?) {
        do {
            let success = try JSONDecoder().decode(success, from: responseData)
            return (success, nil)
        } catch let error as DecodingError {
            let errMsg = extractDecodingErrorMsg(error)
            let internalError = InternalError(debugMsg: errMsg)
            return (nil, internalError)
        } catch {
            let internalError = InternalError(debugMsg: error.localizedDescription)
            return (nil, internalError)
        }
    }
    
    private func handleFailure<F: Decodable>(_ failure: F.Type, responseData: Data) -> ZAPError<Any> {
        do {
            let failure = try JSONDecoder().decode(failure, from: responseData)
            return ZAPError.failureError(failure)
        } catch let error as DecodingError {
            let errMsg = extractDecodingErrorMsg(error)
            let internalError = InternalError(debugMsg: errMsg)
            return ZAPError.internalError(internalError)
        } catch {
            let internalError = InternalError(debugMsg: error.localizedDescription)
            return ZAPError.internalError(internalError)
        }
    }
    
    private func extractEncodingErrorMsg(_ error: EncodingError) -> String {
        switch error {
        case .invalidValue(let value, let context):
            debugPrint("EncodingError.invalidValue: (\(value), \(context))")
            return context.debugDescription
        @unknown default:
            debugPrint("EncodingError.unknownDefault: \(error)")
            return error.localizedDescription
        }
    }
    
    private func extractDecodingErrorMsg(_ error: DecodingError) -> String {
        switch error {
        case .dataCorrupted(let value):
            debugPrint("DecodingError.dataCorrupted: \(value)")
            return value.debugDescription
        case .typeMismatch(let type, let value):
            debugPrint("DecodingError.typeMismatch: (\(type), \(value))")
            return value.debugDescription
        case .valueNotFound(let type, let value):
            debugPrint("DecodingError.valueNotFound: (\(type), \(value))")
            return value.debugDescription
        case .keyNotFound(let key, let value):
            debugPrint("DecodingError.keyNotFound: (\(key), \(value))")
            return value.debugDescription
        @unknown default:
            debugPrint("DecodingError.unknownDefault: \(error)")
            return error.localizedDescription
        }
    }
}
