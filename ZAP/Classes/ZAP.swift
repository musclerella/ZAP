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
//TODO: For buildURL() if url parameter has a slash on the end of the string remove it before adding query items
public class Zap {
    
    public static let `default` = Zap()

    public weak var delegate: URLSessionDelegate?
    
    public init() { }
    
    public func post<S: Decodable, F: Decodable>(url: String, body: Encodable, success: S.Type, failure: F.Type, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        
        // 1. Build URL
        guard let url = URL(string: url) else {
            let internalError = InternalError(debugMsg: ZAPErrorMsg.malformedURL.rawValue)
            return .failure(ZAPError.internalError(internalError))
        }

        do {
            // 2. Build Request Body
            let httpBody = try JSONEncoder().encode(body)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = HTTPMethod.post.rawValue.uppercased()
            urlRequest.allHTTPHeaderFields = headers
            urlRequest.httpBody = httpBody
            // 3. Perform Request
            let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)
            let response = try await urlSession.data(for: urlRequest)
            // 4. Parse Response
            let urlResponse = response.1
            let responseData = response.0
            let jsonDecoder = JSONDecoder()

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
        } catch let error as EncodingError {
            let errMsg = extractEncodingErrorMsg(error)
            let internalError = InternalError(debugMsg: errMsg)
            return .failure(ZAPError.internalError(internalError))
        } catch {
            let internalError = InternalError(debugMsg: error.localizedDescription)
            return .failure(ZAPError.internalError(internalError))
        }
    }
    
    public func get<S: Decodable, F: Decodable>(url: String, queryItems: [URLQueryItem]? = nil, success: S.Type, failure: F.Type, headers: [String: String]? = nil) async throws -> Result<S, ZAPError<F>> {
        
        // 1. Build URL
        let urlResult = buildURL(url: url, queryItems: queryItems)
        guard let url = urlResult.0 else {
            if case .internalError(let internalError) = urlResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the URL.")))
            }
        }
            
        // 2. Build Request Body
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.post.rawValue.uppercased()
        urlRequest.allHTTPHeaderFields = headers

        return .failure(ZAPError.internalError(InternalError(debugMsg: ZAPErrorMsg.unknown.rawValue)))
    }
}

extension Zap {
    
    private func buildURL(url: String, queryItems: [URLQueryItem]? = nil) -> (URL?, ZAPError<Any>?) {
        // 1. Build URL
        if let queryItems, var urlComponents = URLComponents(string: url) {
            urlComponents.queryItems = queryItems
            return (urlComponents.url, nil)
        } else if let url = URL(string: url) {
            return (url, nil)
        } else {
            let internalError = InternalError(debugMsg: ZAPErrorMsg.malformedURL.rawValue)
            return (nil, ZAPError.internalError(internalError))
        }
    }

    //TODO: Should we return the Swift.Result Type directly from this function and then return the function in the primary method?
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

    //TODO: Should we return the Swift.Result Type directly from this function and then return the function in the primary method?
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
