//
//  NetworkingRequestDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

protocol NetworkingRequestDelegate {
    
}

extension NetworkingRequestDelegate {
    
    func configureURLSession(delegate: URLSessionDelegate, urlCache: URLCache, cachePolicy: NSURLRequest.CachePolicy?) -> URLSession {

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
//        configuration.urlCache = isMemoryCacheEnabled ? URLCache.shared : nil
        configuration.requestCachePolicy = cachePolicy ?? ZAP.defaultCachePolicy

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
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

    func buildRequest(task: NetworkTask, method: HTTPMethod, url: URL, body: Encodable? = nil, headers: [String: String]? = nil, boundary: String = "", basicAuthCredentials: String?) -> (URLRequest?, InternalError?) {
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
    
    func extractEncodingErrorMsg(_ error: EncodingError) -> String {
        switch error {
        case .invalidValue(let value, let context):
            debugPrint("EncodingError.invalidValue: (\(value), \(context))")
            return context.debugDescription
        @unknown default:
            debugPrint("EncodingError.unknownDefault: \(error)")
            return error.localizedDescription
        }
    }
}
