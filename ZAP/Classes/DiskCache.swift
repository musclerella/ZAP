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
            throw InternalError(debugMsg: error.localizedDescription)
        }
    }
    
    func storeJSONData(request: URLRequest, data: Data) {
        if let cacheableURL = request.url?.absoluteString {
            let fileURL = cacheDirectory.appendingPathComponent(cacheableURL)
            do {
                try data.write(to: fileURL, options: .atomicWrite)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func cachedValueAt(url: String) -> Data? {
        let filePath = cacheDirectory.appendingPathComponent(url)
        return try? Data(contentsOf: filePath)
    }
    
    func cachedValueAt<S: Decodable>(url: String, success: S.Type) -> S? {
        guard let cachedData = cachedValueAt(url: url) else { return nil }
        return try? convertSuccessDataIntoStruct(success, responseData: cachedData)
    }
}
