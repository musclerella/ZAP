//
//  NetworkingBase.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/2/24.
//

import Foundation

enum NetworkTasks {
    case multipartFormData
    case uploadSingleFile
}

public class NetworkingBase: NSObject {
    
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
    
    func buildRequest(method: HTTPMethod, url: URL, body: Encodable? = nil, headers: [String: String]? = nil) -> (URLRequest?, InternalError?) {
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
    
    func parseResponse<S: Decodable, F: Decodable>(response: (Data, URLResponse), success: S.Type, failure: F.Type) -> Result<S, ZAPError<F>> {
        
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
            return .success(success)
        } else if let internalError = successResult.1 {
            return .failure(ZAPError.internalError(internalError))
        } else {
            return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while decoding the success.")))
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

    private func handleSuccess<S: Decodable>(_ success: S.Type, responseData: Data) -> (S?, InternalError?) {
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
