//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation
import UniformTypeIdentifiers

public typealias DataTransferProgress = (Float) -> Void

class FileUploader: NetworkingBase {
    
    let session: URLSession
    var progress: DataTransferProgress?
    
    override init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        super.init()
    }
        
    func uploadFile<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress?) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequestForSingleFileUpload(httpMethod, to: url, success: success, failure: failure, fileURL: fileURL, queryItems: queryItems, headers: headers, progress: progress)
    }

    func uploadFilesWithData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequestForMultipartFormData(httpMethod, to: url, success: success, failure: failure, files: files, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }
}

//MARK: Private Methods
extension FileUploader {
    
    private func createMultipartBody(boundary: String, files: [ZAPFile], formData: [String: Any]? = nil) -> Data {
        var body = Data()
        // Add form data
        if let formData {
            for (key, value) in formData {
                if let data = "--\(boundary)\r\n".data(using: .utf8) {
                    body.append(data)
                }
                if let data = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) {
                    body.append(data)
                }
                if let data = "\(value)\r\n".data(using: .utf8) {
                    body.append(data)
                }
            }
        }
        // Add files
        for file in files {
            switch file {
            case .url(let fileURL, serverFileTypeIdentifier: let serverFileTypeIdentifier, mimeType: let mimeType):

                let filename = fileURL.lastPathComponent
                let mimeType = mimeType?.rawValue ?? extractMimeType(for: fileURL)
                
                body = addFileToHTTPBody(body: &body, boundary: boundary, filename: filename, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)
               
                if let fileData = try? Data(contentsOf: fileURL) {
                    body.append(fileData)
                }
                if let data = "\r\n".data(using: .utf8) {
                    body.append(data)
                }
            case .data(let fileData, serverFileTypeIdentifier: let serverFileTypeIdentifier, mimeType: let mimeType):
                
                let filename = UUID().uuidString
                let mimeType = mimeType.rawValue
                
                body = addFileToHTTPBody(body: &body, boundary: boundary, filename: filename, serverFileTypeIdentifier: serverFileTypeIdentifier, mimeType: mimeType)

                body.append(fileData)
                
                if let data = "\r\n".data(using: .utf8) {
                    body.append(data)
                }
            }
        }
        if let data = "--\(boundary)--\r\n".data(using: .utf8) {
            body.append(data)
        }
        return body
    }
    
    private func addFileToHTTPBody(body: inout Data, boundary: String, filename: String, serverFileTypeIdentifier: String, mimeType: String) -> Data {
        if let data = "--\(boundary)\r\n".data(using: .utf8) {
            body.append(data)
        }
        if let data = "\(HTTPHeader.Key.contentDisposition.rawValue): form-data; name=\"\(serverFileTypeIdentifier.isEmpty ? "file" : serverFileTypeIdentifier)\"; filename=\"\(filename)\"\r\n".data(using: .utf8) {
            body.append(data)
        }
        if let data = "\(HTTPHeader.Key.contentType.rawValue): \(mimeType)\r\n\r\n".data(using: .utf8) {
            body.append(data)
        }
        return body
    }
    
    private func extractMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension
        if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimeType
        }
        return MimeType.bin.rawValue
    }
    
    private func addDefaultHeadersIfAbsent(for task: NetworkTasks, urlRequest: inout URLRequest, boundary: String = "") -> URLRequest {
        switch task {
        case .uploadSingleFile:
            if urlRequest.allHTTPHeaderFields?[HTTPHeader.Key.contentType.rawValue] == nil {
                urlRequest.addValue(HTTPHeader.Value.ContentType.octetStream.rawValue, forHTTPHeaderField: HTTPHeader.Key.contentType.rawValue)
            }
        case .multipartFormData:
            if urlRequest.allHTTPHeaderFields?[HTTPHeader.Key.contentType.rawValue] == nil {
                urlRequest.addValue(HTTPHeader.Value.ContentType.multipartFormData.rawValue.appending(boundary), forHTTPHeaderField: HTTPHeader.Key.contentType.rawValue)
            }
        }
        return urlRequest
    }
    
    private func buildAndExecuteRequestForMultipartFormData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress?) async -> Result<S, ZAPError<F>> {
        self.progress = progress
        // 1. Build server url
        let serverURLResult = buildURL(url: url, queryItems: queryItems)
        guard let serverURL = serverURLResult.0 else {
            if let internalError = serverURLResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the server URL.")))
            }
        }
        // 2. Build request
        let requestResult = buildRequest(method: httpMethod, url: serverURL, body: body, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 3. Add default http headers if not provided
        let boundary = UUID().uuidString
        request = addDefaultHeadersIfAbsent(for: .multipartFormData, urlRequest: &request, boundary: boundary)
        // 4. Create multipart/form-data http body
        var multipartHttpBody: Data?
        if let httpBody = request.httpBody {
            let jsonSerializationResult = httpBody.convertToDictionary()
            if let formData = jsonSerializationResult.0 {
                multipartHttpBody = createMultipartBody(boundary: boundary, files: files, formData: formData)
            } else if let internalError = jsonSerializationResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An known error occurred while converting http body data to a json dictionary")))
            }
        } else {
            multipartHttpBody = createMultipartBody(boundary: boundary, files: files)
        }
        request.httpBody = multipartHttpBody
    }
    
    private func buildAndExecuteRequestForSingleFileUpload<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress?) async -> Result<S, ZAPError<F>> {
        self.progress = progress
        // 1. Build server url
        let serverURLResult = buildURL(url: url, queryItems: queryItems)
        guard let serverURL = serverURLResult.0 else {
            if let internalError = serverURLResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the server URL.")))
            }
        }
        // 2. Get file data from local file URL
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return .failure(ZAPError.internalError(InternalError(debugMsg: ZAPErrorMsg.failedToReadDataFromFilePath.rawValue)))
        }
        // 3. Build request
        let requestResult = buildRequest(method: httpMethod, url: serverURL, body: nil, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(InternalError(debugMsg: internalError.localizedDescription)))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 4. Add default headers if absent
        request = addDefaultHeadersIfAbsent(for: .uploadSingleFile, urlRequest: &request)
        // 4. Perform request
        return await performRequestAndParseResponse(urlRequest: request, success: success, failure: failure, fileData: fileData)
    }
    
    private func performRequestAndParseResponse<S: Decodable, F: Decodable>(urlRequest: URLRequest, success: S.Type, failure: F.Type, fileData: Data) async -> Result<S, ZAPError<F>> {
        // Perform Request
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        do {
            let response = try await session.upload(for: urlRequest, from: fileData, delegate: self)
            return parseResponse(response: response, success: success, failure: failure)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
}

//MARK: URLSessionTaskDelegate
extension FileUploader: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        progress?(Float(totalBytesSent) / Float(totalBytesExpectedToSend))
    }
    
    //TODO: Is this method called with async/await?
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            print(error)
        } else {
            print("Successfully uploaded file.")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (.performDefaultHandling, nil)
    }
}

//MARK: URLSessionDelegate
extension FileUploader: URLSessionDelegate {
    
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
