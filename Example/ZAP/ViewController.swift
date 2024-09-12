//
//  ViewController.swift
//  ZAP
//
//  Created by samuscarella on 08/28/2024.
//  Copyright (c) 2024 samuscarella. All rights reserved.
//

import UIKit
import ZAP
import Alamofire

class ViewController: UIViewController {
    
    // Base URL
    let baseURL: String = "https://localhost:443"
    
    // Endpoints
    let postOnePath: String = "/post/one"
    let uploadFilePath: String = "/upload/file"
    
    let localFilePath: URL = URL(string: "asdf/asdf/asdf")!
    let localFileData: Data = Data()

    override func viewDidLoad() {
        super.viewDidLoad()

//        postCall()
//        getCall()
        uploadFile()
    }
    
    private func postCall() {

        let body = PostOneRequestBody(name: "Stephen Muscarella", age: 29)
        Task {
            let result = await Zap.send(.post, url: baseURL.appending(postOnePath), success: PostOneResponseBody.self, failure: ServerError.self, body: body)
            switch result {
            case .success(let success): break
                // Do something with the success
            case .failure(let error): break
                // Do something with the error
            }
        }
    }
    
    private func getCall() {
        
//        let queryItems: [URLQueryItem] = [
//            URLQueryItem(name: "paramOne", value: "==??///,,+54=="),
//            URLQueryItem(name: "paramTwo", value: "=`==~!@#$%^&*()_-=+<>.?==%%%/////,,,Gir affe=")
//        ]
//        
//        Task {
//            let result = await Zap.send(.get, url: baseURL, success: PostOneResponseBody.self, failure: ServerError.self, queryItems: queryItems, headers: nil)
//            switch result {
//            case .success(let success):
//                dump(success)
//            case .failure(let zapError):
//                switch zapError {
//                case .failureError(let failureError):
//                    dump(failureError)
//                case .internalError(let internalError):
//                    dump(internalError)
//                }
//            }
//        }
    }
    
    private func uploadFile() {
        
        if let path = Bundle.main.url(forResource: "arctic_tundra", withExtension: "mp4") {
            Task {
                let result = await ZAP().sendFile(.post, to: baseURL.appending(uploadFilePath), success: SuccessResponse.self, failure: ServerError.self, fileURL: path, queryItems: nil, headers: nil) { cachedValue in
                    // Update the UI with a cached value until new data is acquired
                } progress: { progress in
                    // Do something with the file transfer progress
                }
            }
        }
    }

    private func uploadFilesWithData() {
        
        let zapFiles: [ZAPFile] = [
            ZAPFile.url(localFilePath, serverFileTypeIdentifier: "Audio", mimeType: .mp3),
            ZAPFile.data(localFileData, serverFileTypeIdentifier: "Primary_Video", mimeType: .mpeg)
        ]
        
        Task {
            let result = await ZAP().sendFilesWithData(.get, to: baseURL.appending(postOnePath), success: SuccessResponse.self, failure: ServerError.self, files: zapFiles, body: nil, queryItems: nil, headers: nil, cachedSuccess: nil) { progress in
                // Do something with the file transfer progress
            }
            
            switch result {
            case .success(let successResponse): break
                // Do something with the success
            case .failure(let errorObject): break
                // Do something with the error
            }
        }
    }
    
    private func downloadFile() {
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "age", value: "30"),
            URLQueryItem(name: "birthday", value: "04221995")
        ]

        Task {
            let result = await ZAP().receiveFile(.get, from: baseURL.appending(postOnePath), body: nil, queryItems: queryItems, headers: nil, cachedFile: nil, progress: nil)
        }
        
        
        Task {
            let result = await ZAP().cacheInMemory().send(url: baseURL.appending(postOnePath), success: SuccessResponse.self, failure: ServerError.self) { cachedSuccess in
                // Update the UI temporarily with cached data until new data is received from the server
            }
        }
    }
}

//TODO: Research pros/cons for adding a header key of `Connection` and using different values

//<NSHTTPURLResponse: 0x600000267120> { URL: https://localhost:443/post/one } { Status Code: 200, Headers {
//    Connection =     (
//        "keep-alive"
//    );
//    "Content-Length" =     (
//        2
//    );
//    "Content-Type" =     (
//        "text/plain; charset=utf-8"
//    );
//    Date =     (
//        "Thu, 29 Aug 2024 21:21:12 GMT"
//    );
//    Etag =     (
//        "W/\"2-nOO9QiTIwXgNtWtBJezz8kv3SLc\""
//    );
//    "Keep-Alive" =     (
//        "timeout=5"
//    );
//    "X-Powered-By" =     (
//        Express
//    );
//} }
