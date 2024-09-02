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
//MARK: Public Methods
public class Zap: NSObject {
    
    public static let `default` = Zap()
    
    public init() {
    }
    
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
    
    public func uploadFile<S: Decodable, F: Decodable>(url: String, success: S.Type, failure: F.Type, fileURL: String, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        
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
        
        let requestResult = buildRequest(url: url, method: method, body: body, headers: headers)
        if let request = requestResult.0 {
            return await performRequestAndParseResponse(urlRequest: request, success: success, failure: failure)
        } else if let internalError = requestResult.1 {
            return .failure(ZAPError.internalError(internalError))
        } else {
            return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
        }
    }
    
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
    
    private func buildRequest(url: URL, method: HTTPMethod, body: Encodable? = nil, headers: [String: String]? = nil) -> (URLRequest?, InternalError?) {
        // 2. Build Request Body
        do {
            var httpBody: Data?
            if let body {
                httpBody = try JSONEncoder().encode(body)
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue.uppercased()
            urlRequest.allHTTPHeaderFields = headers
            urlRequest.httpBody = httpBody

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

    private func performRequestAndParseResponse<S: Decodable, F: Decodable>(urlRequest: URLRequest, success: S.Type, failure: F.Type) async -> Result<S, ZAPError<F>> {
        // 3. Perform Request
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        do {
            let response = try await urlSession.data(for: urlRequest)
            // 4. Parse Response
            let urlResponse = response.1
            let responseData = response.0

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
                return .success(success)
            } else if let internalError = successResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while decoding the success.")))
            }
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
    
    private func handleFailure<F: Decodable>(_ failure: F.Type, responseData: Data) -> ZAPError<Any> {
        // Failure
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

    private func handleSuccess<S: Decodable>(_ success: S.Type, responseData: Data) -> (S?, InternalError?) {
        // Success
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
