//
//  ZAP.swift
//  ZAP
//
//  Created by Stephen Muscarella on 8/24/24.
//

import Foundation

//TODO: Is there some benefit of using delegateQueue? (OperationQueue)
//TODO: Is there a range for success status codes?
//TODO: Make multiple function signatures for each HTTPMethod
//TODO: Multipart file upload for files larger than 100 MB
//TODO: Add support to all public method signatures for the keyword 'static'

//MARK: Public Methods
public class Zap: NetworkingBase {

    public static let `default` = Zap()

    public func post<S: Decodable, F: Decodable>(url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: .post, url: url, success: success, failure: failure, body: body, queryItems: queryItems, headers: headers)
    }
    
    public func get<S: Decodable, F: Decodable>(url: String, success: S.Type, failure: F.Type, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: .get, url: url, success: success, failure: failure, queryItems: queryItems, headers: headers)
    }
    
    public func put<S: Decodable, F: Decodable>(url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: .put, url: url, success: success, failure: failure, body: body, queryItems: queryItems, headers: headers)
    }
    
    public func delete<S: Decodable, F: Decodable>(url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: .delete, url: url, success: success, failure: failure, body: body, queryItems: queryItems, headers: headers)
    }
    
    public func uploadFile<S: Decodable, F: Decodable>(to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: UploadProgress? = nil) async throws -> Result<S, ZAPError<F>> {
        // 1. Build Server URL
        let serverURLResult = buildURL(url: url, queryItems: queryItems)
        guard let serverURL = serverURLResult.0 else {
            if let internalError = serverURLResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the server URL.")))
            }
        }
        // 3. Upload File
        let fileUploader = FileUploader()
        return await fileUploader.uploadFile(to: serverURL, success: success, failure: failure, from: fileURL, headers: headers, progress: progress)
    }
    
    public func updateFile<S: Decodable, F: Decodable>(to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: UploadProgress? = nil) async throws -> Result<S, ZAPError<F>> {
        // 1. Build Server URL
        let serverURLResult = buildURL(url: url, queryItems: queryItems)
        guard let serverURL = serverURLResult.0 else {
            if let internalError = serverURLResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the server URL.")))
            }
        }
        // 3. Update File
        let fileUploader = FileUploader()
        return await fileUploader.updateFile(to: serverURL, success: success, failure: failure, from: fileURL, headers: headers, progress: progress)
    }
}

//MARK: Private Methods
extension Zap {
    
    private func buildURL(url: String, queryItems: [URLQueryItem]? = nil) -> (URL?, InternalError?) {
        // 1. Build URL
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

    private func buildAndExecuteRequest<S: Decodable, F: Decodable>(method: HTTPMethod, url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async -> Result<S, ZAPError<F>> {
        // 1. Build URL
        let urlResult = buildURL(url: url, queryItems: queryItems)
        guard let url = urlResult.0 else {
            if let internalError = urlResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the URL.")))
            }
        }
        
        let requestResult = buildRequest(task: .standard, method: method, url: url, body: body, headers: headers)
        guard let request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        return await performRequestAndParseResponse(urlRequest: request, success: success, failure: failure)
    }

    private func performRequestAndParseResponse<S: Decodable, F: Decodable>(urlRequest: URLRequest, success: S.Type, failure: F.Type) async -> Result<S, ZAPError<F>> {
        // 3. Perform Request
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        do {
            let response = try await urlSession.data(for: urlRequest)
            return parseResponse(response: response, success: success, failure: failure)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
}

//MARK: URLSessionDelegate
extension Zap: URLSessionDelegate {
        
//    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
//        
//    }
//    
//    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
//        
//    }
//    
//    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        
//    }
}

//        urlRequest.httpBodyStream =
//        urlRequest.allowsCellularAccess =
//        urlRequest.allowsConstrainedNetworkAccess =
//        urlRequest.allowsExpensiveNetworkAccess =
//        urlRequest.assumesHTTP3Capable =
//        urlRequest.httpShouldHandleCookies =
//        urlRequest.httpShouldUsePipelining =
//        urlRequest.requiresDNSSECValidation =
//        urlRequest.attribution =
//        urlRequest.mainDocumentURL =
//        urlRequest.networkServiceType =
