//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation

//public struct UploadProgress {
//    public let progressHandler: (Double) -> Void
////    public let completionHandler: (Result<Void, ZAPError<Any>>) -> Void
//}

public typealias UploadProgress = (Float) -> Void

class FileUploader: NetworkingBase {
    
    let session: URLSession
    var progress: UploadProgress?
    
    override init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        super.init()
    }
        
    func uploadFile<S: Decodable, F: Decodable>(to url: URL, success: S.Type, failure: F.Type, from fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: UploadProgress?) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(.post, to: url, success: success, failure: failure, from: fileURL, queryItems: queryItems, headers: headers, progress: progress)
    }
    
    func updateFile<S: Decodable, F: Decodable>(to url: URL, success: S.Type, failure: F.Type, from fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: UploadProgress?) async -> Result<S, ZAPError<F>> {
        return await buildAndExecuteRequest(.put, to: url, success: success, failure: failure, from: fileURL, queryItems: queryItems, headers: headers, progress: progress)
    }
}

//MARK: Private Methods
extension FileUploader {
    
    private func buildAndExecuteRequest<S: Decodable, F: Decodable>(_ httpMethod: HTTPMethod, to url: URL, success: S.Type, failure: F.Type, from fileURL: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil, progress: UploadProgress?) async -> Result<S, ZAPError<F>> {
        self.progress = progress
        // Get file data from local file URL
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return .failure(ZAPError.internalError(InternalError(debugMsg: ZAPErrorMsg.failedToReadFileDataFromFile.rawValue)))
        }
        // Build request
        //TODO: Task might need to be inputed here if `buildAndExecuteRequest` reuses this logic for other variations of uploading files
        let requestResult = buildRequest(task: .uploadSingleFile, method: httpMethod, url: url, body: nil, headers: headers)
        guard let request = requestResult.0 else {
            if let internalError = requestResult.1 {
                return .failure(ZAPError.internalError(InternalError(debugMsg: internalError.localizedDescription)))
            } else {
                return .failure(ZAPError.internalError(InternalError(debugMsg: "An unknown error occurred while building the request.")))
            }
        }
        // Perform request
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
