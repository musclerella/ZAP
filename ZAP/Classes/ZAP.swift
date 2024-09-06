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

//MARK: Public Methods
public class Zap: NetworkingBase {

    public static let `default` = Zap()
    
    public func send<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .get, url: String, success: S.Type, failure: F.Type, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(method: httpMethod, url: url, success: success, failure: failure, body: body, queryItems: queryItems, headers: headers)
    }
    
    public func sendFile<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .get, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        let fileUploader = FileUploader()
        return await fileUploader.uploadFile(httpMethod, to: url, success: success, failure: failure, fileURL: fileURL, headers: headers, progress: progress)
    }
        
    func sendFilesWithData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod = .post, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        let fileUploader = FileUploader()
        return await fileUploader.uploadFilesWithData(httpMethod, to: url, success: success, failure: failure, files: files, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }
}

//MARK: Private Methods
extension Zap {

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
        let requestResult = buildRequest(method: method, url: url, body: body, headers: headers)
        guard let request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 3. Perform Request and Parse Response
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
