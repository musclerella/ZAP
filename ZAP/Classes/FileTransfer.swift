//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation
import UniformTypeIdentifiers

public typealias DataTransferProgress = (Float) -> Void
public typealias FileData = (Data) -> Void

typealias MultipartFormData = Data

class FileTransfer: NetworkingBase {
    
    let session: URLSession
    var progress: DataTransferProgress?
    
    override init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    }
    
    func downloadFile(_ httpMethod: HTTPMethod, from url: String, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedFile: FileData? = nil, progress: DataTransferProgress? = nil) async -> Result<Data, ZAPError<Any>> {
        do {
            let fileData = try await buildAndExecuteRequestForSingleFileDownload(httpMethod, from: url, body: body, queryItems: queryItems, headers: headers, cachedFile: cachedFile, progress: progress)
            return .success(fileData)
        } catch let error as ZAPError<Any> {
            return .failure(error)
        } catch let error as InternalError {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.internalErrorMessage))
        } catch {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.localizedDescription))
        }
    }

    func uploadFile<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedSuccess: CachedSuccess<S>? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        do {
            let successObject = try await buildAndExecuteRequestForSingleFileUpload(httpMethod, to: url, success: success, failure: failure, fileURL: fileURL, queryItems: queryItems, headers: headers, cachedSuccess: cachedSuccess, progress: progress)
            return .success(successObject)
        } catch let error as ZAPError<F> {
            return .failure(error)
        } catch let error as InternalError {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.internalErrorMessage))
        } catch {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.localizedDescription))
        }
    }

    func uploadFilesWithData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedSuccess: CachedSuccess<S>? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        do {
            let successObject = try await buildAndExecuteRequestForMultipartFormData(httpMethod, to: url, success: success, failure: failure, files: files, body: body, queryItems: queryItems, headers: headers, cachedSuccess: cachedSuccess, progress: progress)
            return .success(successObject)
        } catch let error as ZAPError<F> {
            return .failure(error)
        } catch let error as InternalError {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.internalErrorMessage))
        } catch {
            return .failure(ZAPError(serverError: nil, internalErrorMsg: error.localizedDescription))
        }
    }
}

//MARK: Private Methods
extension FileTransfer: MemoryCacheDelegate, DiskCacheDelegate {
    
    private func createMultipartBody(boundary: String, files: [ZAPFile], formData: [String: Any]? = nil) throws -> Data {
        var body = MultipartFormData()
        
        for file in files {
            switch file {
            case .url(let fileURL, serverFileTypeIdentifier: let serverFileTypeIdentifier, mimeType: let mimeType):
                try body.addZAPFile(boundary: boundary, fileURL: fileURL, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)
            case .data(let fileData, serverFileTypeIdentifier: let serverFileTypeIdentifier, mimeType: let mimeType):
                try body.addZAPFile(boundary: boundary, fileData: fileData, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)
            }
        }
        
        if let formData {
            try body.addFormDataToHTTPBody(boundary: boundary, formData: formData)
        }

        body.append(try "--\(boundary)--\r\n".encode(using: .utf8))
        return body
    }

    private func buildAndExecuteRequestForSingleFileDownload(_ httpMethod: HTTPMethod, from url: String, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedFile: FileData? = nil, progress: DataTransferProgress? = nil) async throws -> Data {
        self.progress = progress

        do {
            let serverURL = try buildURL(url: url, queryItems: queryItems)
            var request = try buildRequest(task: .downloadSingleFile, method: httpMethod, url: serverURL, body: body, headers: headers, basicAuthCredentials: basicAuthCredentials)

            if let cachedValue = fetchFromMemoryCache(request: request) {
                cachedFile?(cachedValue)
            } else if let cachedValue = fetchFromDiskCache(url: url) {
                cachedFile?(cachedValue)
            }

            return try await performRequestAndParseResponseForSingleFileDownload(urlRequest: &request)

        } catch {
            throw error
        }
    }
    
    private func buildAndExecuteRequestForSingleFileUpload<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedSuccess: CachedSuccess<S>? = nil, progress: DataTransferProgress?) async throws -> S {
        self.progress = progress

        do {
            let serverURL = try buildURL(url: url, queryItems: queryItems)
            var request = try buildRequest(task: .uploadSingleFile, method: httpMethod, url: serverURL, body: nil, headers: headers, basicAuthCredentials: basicAuthCredentials)
            request.addDefaultHeadersIfApplicable(for: .uploadSingleFile)

            guard let fileData = try? Data(contentsOf: fileURL) else {
                throw InternalError(ZAPErrorMsg.readDataFromFilePath.rawValue)
            }

            if let cachedValue = fetchFromMemoryCache(request: request, success: success) {
                cachedSuccess?(cachedValue)
            } else if let cachedValue = fetchFromDiskCache(url: serverURL.absoluteString, success: success) {
                cachedSuccess?(cachedValue)
            }

            return try await performRequestAndParseResponseForSingleFileUpload(urlRequest: &request, success: success, failure: failure, fileData: fileData)

        } catch {
            throw error
        }
    }
    
    private func buildAndExecuteRequestForMultipartFormData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, cachedSuccess: CachedSuccess<S>? = nil, progress: DataTransferProgress?) async throws -> S {
        self.progress = progress

        do {
            let serverURL = try buildURL(url: url, queryItems: queryItems)
            let boundary = UUID().uuidString
            var request = try buildRequest(task: .multipartFormData, method: httpMethod, url: serverURL, body: body, headers: headers, boundary: boundary, basicAuthCredentials: basicAuthCredentials)
            request.addDefaultHeadersIfApplicable(for: .multipartFormData, boundary: boundary)

            var multipartHttpBody: Data?
            if let httpBody = request.httpBody, let formData = try httpBody.convertToDictionary() {
                multipartHttpBody = try createMultipartBody(boundary: boundary, files: files, formData: formData)
            } else {
                multipartHttpBody = try createMultipartBody(boundary: boundary, files: files)
            }

            request.httpBody = multipartHttpBody

            if let cachedValue = fetchFromMemoryCache(request: request, success: success) {
                cachedSuccess?(cachedValue)
            } else if let cachedValue = fetchFromDiskCache(url: serverURL.absoluteString, success: success) {
                cachedSuccess?(cachedValue)
            }

            return try await performRequestAndParseResponseForMultipartFormData(urlRequest: &request, success: success, failure: failure)

        } catch {
            throw error
        }
    }
    
    private func performRequestAndParseResponseForSingleFileDownload(urlRequest: inout URLRequest) async throws -> Data {
        do {
            let session = configureURLSession(delegate: self, urlCache: isMemoryCacheEnabled ? cache : nil, cachePolicy: cachePolicy)
            let response = try await session.download(for: urlRequest, delegate: self)
            return try parseResponseForDownload(response, requestForCaching: &urlRequest)
        } catch {
            throw error
        }
    }
        
    private func performRequestAndParseResponseForSingleFileUpload<S: Decodable, F: Decodable>(urlRequest: inout URLRequest, success: S.Type, failure: F.Type, fileData: Data) async throws -> S {
        do {
            let session = configureURLSession(delegate: self, urlCache: isMemoryCacheEnabled ? cache : nil, cachePolicy: cachePolicy)
            let response = try await session.upload(for: urlRequest, from: fileData, delegate: self)
            return try parseResponse(response, requestForCaching: &urlRequest, success: success, failure: failure)
        } catch {
            throw error
        }
    }

    private func performRequestAndParseResponseForMultipartFormData<S: Decodable, F: Decodable>(urlRequest: inout URLRequest, success: S.Type, failure: F.Type) async throws -> S {
        do {
            let session = configureURLSession(delegate: self, urlCache: isMemoryCacheEnabled ? cache : nil, cachePolicy: cachePolicy)
            let response = try await session.data(for: urlRequest)
            return try parseResponse(response, requestForCaching: &urlRequest, success: success, failure: failure)
        } catch {
            throw error
        }
    }
    
    func parseResponseForDownload(_ response: (URL, URLResponse), requestForCaching: inout URLRequest) throws -> Data {
        
        let meteoriteURL = response.0
        let urlResponse = response.1
        
        debugPrint(urlResponse)

        guard let httpURLResponse = urlResponse as? HTTPURLResponse, ZAP.successStatusCodes.contains(httpURLResponse.statusCode) else {
            let urlString = urlResponse.url?.absoluteString ?? ""
            throw InternalError(ZAPErrorMsg.downloadFile.rawValue + urlString)
        }

        let fileData: Data = try meteoriteURL.extractData()

        if isMemoryCacheEnabled {
            let fileSizeInMB = getFileSizeInMegabytes(at: meteoriteURL)
            if fileSizeInMB <= ZAP.maxMemoryCacheFileSize && 0 < fileSizeInMB {
                MemoryCache().storeData(request: &requestForCaching, urlResponse: urlResponse, responseData: fileData)
            }
        }
        if isDiskCacheEnabled {
            DiskCache().storeData(request: requestForCaching, responseData: fileData)
        }
        return fileData
    }
}

//MARK: URLSessionTaskDelegate
extension FileTransfer: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        progress?(Float(totalBytesSent) / Float(totalBytesExpectedToSend))
    }
    
    //TODO: Is this method called with async/await?
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            debugPrint(error)
        } else {
            debugPrint("Successfully uploaded file.")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (.performDefaultHandling, nil)
    }
}

//MARK: URLSessionDelegate
extension FileTransfer: URLSessionDelegate {
    
//    //TODO: Does this method hit only outside of URLSessionTask file uploads or for both?
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
//        return (.performDefaultHandling, nil)
//    }
//    
//    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, needNewBodyStreamForTask task: URLSessionTask) async -> InputStream? {
//        
//    }
//    
//    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest) async -> (URLSession.DelayedRequestDisposition, URLRequest?) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didReceiveInformationalResponse response: HTTPURLResponse) {
//        
//    }
//    
//    func urlSession(_ session: URLSession, needNewBodyStreamForTask task: URLSessionTask, from offset: Int64) async -> InputStream? {
//        
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
//        
//    }
//    
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//
//    }
}
