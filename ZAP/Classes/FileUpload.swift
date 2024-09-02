//
//  FileUpload.swift
//  ZAP
//
//  Created by Stephen Muscarella on 9/1/24.
//

import Foundation

struct UploadProgress {
    let progressHandler: (Double) -> Void
    let completionHandler: (Result<Void, ZAPError<Any>>) -> Void
}

class FileUploader: NSObject, URLSessionTaskDelegate {
        
    var progress: UploadProgress?
    
    func uploadFile(fileURL: URL, to url: URL, progress: UploadProgress) {
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
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

        // Create an upload task with a delegate to monitor progress
        let uploadTask = session.uploadTask(with: request, from: fileData)
        uploadTask.resume()
    }
}
