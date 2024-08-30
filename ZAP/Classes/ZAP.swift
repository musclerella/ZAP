//
//  ZAP.swift
//  ZAP
//
//  Created by Stephen Muscarella on 8/24/24.
//

import Foundation

//TODO: Is there some benefit of using delegateQueue? (OperationQueue)
//TODO: Is there a range for success status codes?
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
                // Failure
                do {
                    let failure = try jsonDecoder.decode(failure, from: responseData)
                    return .failure(ZAPError.failureError(failure))
                } catch let error as DecodingError {
                    let errMsg = extractDecodingErrorMsg(error)
                    let internalError = InternalError(debugMsg: errMsg)
                    return .failure(ZAPError.internalError(internalError))
                } catch {
                    let internalError = InternalError(debugMsg: error.localizedDescription)
                    return .failure(ZAPError.internalError(internalError))
                }
            }
            let successResult = handleSuccess(success, responseData: responseData)
            if let success = successResult.0 {
                return .success(success)
            } else if let internalError = successResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                fatalError()
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
}

extension Zap {
    
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
        do {
            // Success
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
