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

    override func viewDidLoad() {
        super.viewDidLoad()

//        postCall()
//        getCall()
        uploadFile()
    }
    
    private func postCall() {

        let body = PostOneRequestBody(name: "Stephen Muscarella", age: 29)
        Task {
            let result = try await ZAP.post(url: baseURL.appending(postOnePath), success: PostOneResponseBody.self, failure: ServerError.self, body: body)
            switch result {
            case .success(let success):
                dump(success)
            case .failure(let zapError):
                switch zapError {
                case .failureError(let failureError):
                    dump(failureError)
                case .internalError(let internalError):
                    dump(internalError)
                }
            }
        }
    }
    
    private func getCall() {
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "paramOne", value: "==??///,,+54=="),
            URLQueryItem(name: "paramTwo", value: "=`==~!@#$%^&*()_-=+<>.?==%%%/////,,,Gir affe=")
        ]
        
        Task {
            let result = try await ZAP.get(url: baseURL, success: PostOneResponseBody.self, failure: ServerError.self, queryItems: queryItems, headers: nil)
            switch result {
            case .success(let success):
                dump(success)
            case .failure(let zapError):
                switch zapError {
                case .failureError(let failureError):
                    dump(failureError)
                case .internalError(let internalError):
                    dump(internalError)
                }
            }
        }
    }
    
    private func uploadFile() {
        
        if let path = Bundle.main.url(forResource: "arctic_tundra", withExtension: "mp4") {
            Task {
                let result = try await ZAP.uploadFile(to: baseURL.appending(uploadFilePath), success: PostOneResponseBody.self, failure: ServerError.self, fileURL: path, queryItems: nil, headers: nil) { progress in
                    print("Progress: \((progress * 100).rounded(.toNearestOrEven))%")
                }
                switch result {
                case .success(let success):
                    dump(success)
                case .failure(let zapError):
                    switch zapError {
                    case .failureError(let failureError):
                        dump(failureError)
                    case .internalError(let internalError):
                        dump(internalError)
                    }
                }
            }
        }
    }
    
    private func uploadFiles() {
        
    }
    
    private func uploadFilesWithData() {
        
    }
    
    private func downloadFile() {
        
    }
    
    private func downloadFiles() {
        
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
