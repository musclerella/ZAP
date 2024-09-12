//
//  NetworkingBaseDelegate.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/11/24.
//

import Foundation

protocol NetworkingResponseDelegate {
    func deserializeSuccess<S: Decodable>(_ success: S.Type, responseData: Data) throws -> S
    func deserializeServerError<F: Decodable>(_ failure: F.Type, responseData: Data) throws -> F
}

extension NetworkingResponseDelegate {
 
    func deserializeSuccess<S: Decodable>(_ success: S.Type, responseData: Data) throws -> S {
        do {
            return try JSONDecoder().decode(success, from: responseData)
        } catch {
            throw error
        }
    }
    
    func deserializeServerError<F: Decodable>(_ failure: F.Type, responseData: Data) throws -> F {
        do {
            return try JSONDecoder().decode(failure, from: responseData)
        } catch {
            throw error
        }
    }
}
