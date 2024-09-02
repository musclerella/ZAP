//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation

public struct UploadProgress {
    public let progressHandler: (Double) -> Void
    public let completionHandler: (Result<Void, ZAPError<Any>>) -> Void
}

class FileUploader: NSObject {
        
    var progress: UploadProgress?
    
    func uploadFile(fileURL: URL, to url: URL, progress: UploadProgress) async {
        self.progress = progress
        
        // Prepare the file data
        guard let fileData = try? Data(contentsOf: fileURL) else {
            progress.completionHandler(.failure(ZAPError.internalError(InternalError(debugMsg: ZAPErrorMsg.failedToReadFileDataFromFile.rawValue))))
            return
        }
        
        // Create a URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue.uppercased()
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        // Does running this on the main thread prevent using the app while upload is in progress?
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)

        do {
            // How does Node.js receive the upload and does the response return once the file is completely uploaded?
            let response = try await session.upload(for: request, from: fileData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateFile(fileURL: URL, to url: URL, progress: UploadProgress) {
        // PUT
    }
}

//MARK: Private Methods
extension FileUploader {
    
}

//MARK: URLSessionTaskDelegate
extension FileUploader: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
    }
}
