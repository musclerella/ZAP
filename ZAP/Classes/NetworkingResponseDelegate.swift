//
//  NetworkingBaseDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

protocol NetworkingResponseDelegate {
    func convertSuccessDataIntoStruct<S: Decodable>(_ success: S.Type, responseData: Data) throws -> S
    func convertFailureDataIntoStruct<F: Decodable>(_ failure: F.Type, responseData: Data) throws -> F
    func extractDecodingErrorMsg(_ error: DecodingError) -> String
}

extension NetworkingResponseDelegate {
 
    func convertSuccessDataIntoStruct<S: Decodable>(_ success: S.Type, responseData: Data) throws -> S {
        do {
            let success = try JSONDecoder().decode(success, from: responseData)
            return success
        } catch let error as DecodingError {
            let errMsg = extractDecodingErrorMsg(error)
            let internalError = InternalError(debugMsg: errMsg)
            throw internalError
        } catch {
            let internalError = InternalError(debugMsg: error.localizedDescription)
            throw internalError
        }
    }
    
    func convertFailureDataIntoStruct<F: Decodable>(_ failure: F.Type, responseData: Data) throws -> F {
        do {
            let failure = try JSONDecoder().decode(failure, from: responseData)
            return failure
        } catch let error as DecodingError {
            throw ZAPError<Any>.internalError(InternalError(debugMsg: extractDecodingErrorMsg(error)))
        } catch {
            throw ZAPError<Any>.internalError(InternalError(debugMsg: error.localizedDescription))
        }
    }
        
    func extractDecodingErrorMsg(_ error: DecodingError) -> String {
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
