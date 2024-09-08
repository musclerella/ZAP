//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation
import UniformTypeIdentifiers

public typealias DataTransferProgress = (Float) -> Void

class FileTransfer: NetworkingBase {
    
    let session: URLSession
    var progress: DataTransferProgress?
    
    override init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        super.init()
    }
    
    func downloadFile(_ httpMethod: HTTPMethod, from url: String, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<URL, ZAPError<Any>> {
        return await buildAndExecuteRequestForSingleFileDownload(httpMethod, from: url, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }

    func uploadFile<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequestForSingleFileUpload(httpMethod, to: url, success: success, failure: failure, fileURL: fileURL, queryItems: queryItems, headers: headers, progress: progress)
    }

    func uploadFilesWithData<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: String, success: S.Type, failure: F.Type, files: [ZAPFile], body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequestForMultipartFormData(httpMethod, to: url, success: success, failure: failure, files: files, body: body, queryItems: queryItems, headers: headers, progress: progress)
    }
}

//MARK: Private Methods
extension FileTransfer {
    
    private func createMultipartBody(boundary: String, files: [ZAPFile], formData: [String: Any]? = nil) -> (Data?, InternalError?) {
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
                } else {
                    return (nil, InternalError(debugMsg: ZAPErrorMsg.urlToDataConversion.rawValue))
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
        return (body, nil)
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
        } else if let mimeType = FileExtensionMap.getMimeTypeFromExtension(pathExtension) {
            return mimeType
        }
        return MimeType.bin.rawValue
    }

    private func buildAndExecuteRequestForSingleFileDownload(_ httpMethod: HTTPMethod, from url: String, body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: DataTransferProgress? = nil) async -> Result<URL, ZAPError<Any>> {
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
        let requestResult = buildRequest(task: .downloadSingleFile, method: httpMethod, url: serverURL, body: body, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(InternalError(debugMsg: internalError.localizedDescription)))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 3. Perform request
        return await performRequestAndParseResponseForSingleFileDownload(urlRequest: &request)
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
            return .failure(ZAPError.internalError(InternalError(debugMsg: ZAPErrorMsg.readDataFromFilePath.rawValue)))
        }
        // 3. Build request
        let requestResult = buildRequest(task: .uploadSingleFile, method: httpMethod, url: serverURL, body: nil, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(InternalError(debugMsg: internalError.localizedDescription)))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // 4. Add default http headers if not provided
        request = addDefaultHeadersIfApplicable(for: .uploadSingleFile, urlRequest: &request)
        // 5. Perform request
        return await performRequestAndParseResponseForSingleFileUpload(urlRequest: &request, success: success, failure: failure, fileData: fileData)
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
        let requestResult = buildRequest(task: .multipartFormData, method: httpMethod, url: serverURL, body: body, headers: headers)
        guard var request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request")))
            }
        }
        // 3. Create multipart/form-data http body
        let boundary = UUID().uuidString
        var multipartHttpBody: Data?
        if let httpBody = request.httpBody {
            let jsonSerializationResult = httpBody.convertToDictionary()
            if let formData = jsonSerializationResult.0 {
                //TODO: Is throwing internally and publicly returning a Swift.Result failure cleaner? Should not need unknown error conditions
                let multipartHttpBodyResult = createMultipartBody(boundary: boundary, files: files, formData: formData)
                if let httpBody = multipartHttpBodyResult.0 {
                    multipartHttpBody = httpBody
                } else if let internalError = multipartHttpBodyResult.1 {
                    return .failure(ZAPError.internalError(internalError))
                } else {
                    return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while creating the multipart http body")))
                }
            } else if let internalError = jsonSerializationResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while converting http body data to a json dictionary")))
            }
        } else {
            let multipartHttpBodyResult = createMultipartBody(boundary: boundary, files: files)
            if let httpBody = multipartHttpBodyResult.0 {
                multipartHttpBody = httpBody
            } else if let internalError = multipartHttpBodyResult.1 {
                return .failure(ZAPError.internalError(internalError))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while creating the multipart http body")))
            }
        }
        request.httpBody = multipartHttpBody
        // 4. Add default http headers if not provided
        request = addDefaultHeadersIfApplicable(for: .multipartFormData, urlRequest: &request, boundary: boundary)
        // 5. Perform request
        return await performRequestAndParseResponseForMultipartFormData(urlRequest: &request, success: success, failure: failure)
    }
    
    private func performRequestAndParseResponseForSingleFileDownload(urlRequest: inout URLRequest) async -> Result<URL, ZAPError<Any>> {
        do {
            let session = configureURLSessionAndClearChainedConfigurations(delegate: self)
            let response = try await session.download(for: urlRequest, delegate: self)
            return parseResponse(response)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }
        
    private func performRequestAndParseResponseForSingleFileUpload<S: Decodable, F: Decodable>(urlRequest: inout URLRequest, success: S.Type, failure: F.Type, fileData: Data) async -> Result<S, ZAPError<F>> {
        do {
            let session = configureURLSessionAndClearChainedConfigurations(delegate: self)
            let response = try await session.upload(for: urlRequest, from: fileData, delegate: self)
            return parseResponse(response, success: success, failure: failure)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
    }

    private func performRequestAndParseResponseForMultipartFormData<S: Decodable, F: Decodable>(urlRequest: inout URLRequest, success: S.Type, failure: F.Type)  async -> Result<S, ZAPError<F>> {
        do {
            let session = configureURLSessionAndClearChainedConfigurations(delegate: self)
            let response = try await session.data(for: urlRequest)
            return parseResponse(response, success: success, failure: failure)
        } catch {
            return .failure(ZAPError.internalError(InternalError(debugMsg: error.localizedDescription)))
        }
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
