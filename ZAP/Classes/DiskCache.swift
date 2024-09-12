//
//  DiskCache.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/9/24.
//

import Foundation

class DiskCache: NetworkingResponseDelegate {

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ZAPNetworkCache")
    }
    
    func directoryOfCache() -> URL {
        return cacheDirectory
    }
    
    func storeFileFrom(meteoriteURL: URL, for cacheableURL: String) throws {
        let destinationURL = cacheDirectory.appendingPathComponent(cacheableURL)
        do {
            try fileManager.moveItem(at: meteoriteURL, to: destinationURL)
        } catch {
            throw InternalError(error.localizedDescription)
        }
    }
    
    func storeData(request: URLRequest, responseData: Data) {
        if let cacheableURL = request.url?.absoluteString {
            let fileURL = cacheDirectory.appendingPathComponent(cacheableURL)
            do {
                try responseData.write(to: fileURL, options: .atomicWrite)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func retrieveDataAt(url: String) -> Data? {
        let filePath = cacheDirectory.appendingPathComponent(url)
        return try? Data(contentsOf: filePath)
    }
    
    func retrieveSuccessAt<S: Decodable>(url: String, success: S.Type) -> S? {
        guard let cachedData = retrieveDataAt(url: url) else { return nil }
        return try? deserializeSuccess(success, responseData: cachedData)
    }
}
