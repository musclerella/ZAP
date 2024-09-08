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
//TODO: Add support to return an array of progress bars that are attached to naming identifier(s) (IS THIS NEEDED OR SHOULD THIS REQUIREMENT BE PERFORMED WITH SINGLE FILE UPLOAD APIs?

public typealias MeteoriteURL = URL

//MARK: Public Methods
public class ZAP: NetworkingBase {

    public static let `default` = ZAP()
            
    //MARK: Primary Public Signatures
    public func send<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .get, url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: httpMethod, url: url, success: success, failure: failure, body: body, queryItems: queryItems, headers: headers)
    }

    public func sendFile<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .post, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        return await FileTransfer().uploadFile(httpMethod, to: url, success: success, failure: failure, fileURL: fileURL, queryItems: queryItems, headers: headers, progress: progress)
    }

    public func sendFilesWithData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .post, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        return await FileTransfer().uploadFilesWithData(httpMethod, to: url, success: success, failure: failure, files: files, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }

    public func receiveFile(_ httpMethod: HTTPMethod = .get, from url: String, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<MeteoriteURL, ZAPError<Any>> {
        return await FileTransfer().downloadFile(httpMethod, from: url, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }
    
    //MARK: Chained Methods
    public func auth(user: String, pass: String) -> ZAP {
        let credentials = "\(user):\(pass)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        self.basicAuthCredentials = encodedCredentials
        return self
    }
    
    public func auth() -> ZAP {
        // Use global auth configuration
        return self
    }
    
    public func cache(policy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) -> ZAP {
        self.cachePolicy = policy
        return self
    }
}

//MARK: Private Methods
extension ZAP {

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
        // 2. Build Request
        let requestResult = buildRequest(task: .standard, method: method, url: url, body: body, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 3. Perform request and parse response
        return await performRequestAndParseResponse(urlRequest: &request, success: success, failure: failure)
    }

    private func performRequestAndParseResponse<S: Decodable, F: Decodable>(urlRequest: inout URLRequest, success: S.Type, failure: F.Type) async -> Result<S, ZAPError<F>> {
        do {
            let session = configureURLSessionAndClearChainedConfigurations(delegate: self)
            let response = try await session.data(for: urlRequest)
            return parseResponse(response, success: success, failure: failure)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
}

//MARK: URLSessionDelegate
extension ZAP: URLSessionDelegate {
        
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
