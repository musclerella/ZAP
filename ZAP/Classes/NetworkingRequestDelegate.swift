//
//  NetworkingRequestDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

protocol NetworkingRequestDelegate {
    func configureURLSession(delegate: URLSessionDelegate, urlCache: URLCache?, cachePolicy: NSURLRequest.CachePolicy?) -> URLSession
    func buildURL(url: String, queryItems: [URLQueryItem]?) throws -> URL
    func buildRequest(task: NetworkTask, method: HTTPMethod, url: URL, body: Encodable?, headers: [String: String]?, boundary: String, basicAuthCredentials: String?) throws -> URLRequest
}

extension NetworkingRequestDelegate {
    
    func configureURLSession(delegate: URLSessionDelegate, urlCache: URLCache?, cachePolicy: NSURLRequest.CachePolicy?) -> URLSession {

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        configuration.requestCachePolicy = cachePolicy ?? ZAP.defaultCachePolicy

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
        
    func buildURL(url: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        if let queryItems, var urlComponents = URLComponents(string: url) {
            urlComponents.percentEncodedQueryItems = queryItems.percentEncoded()
            if let url = urlComponents.url {
                return url
            }
        } else if let url = URL(string: url) {
            return url
        }
        throw InternalError(ZAPErrorMsg.malformedURL.rawValue)
    }

    func buildRequest(task: NetworkTask, method: HTTPMethod, url: URL, body: Encodable? = nil, headers: [String: String]? = nil, boundary: String = "", basicAuthCredentials: String?) throws -> URLRequest {
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
            urlRequest.addDefaultHeadersIfApplicable(for: task, boundary: boundary)
            
            return urlRequest
            
        } catch {
            throw error
        }
    }
}
