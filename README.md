# ZAP
Simple, straight to the point HTTP Networking

[![Swift](https://img.shields.io/badge/Swift-5-red?style=flat-square)](https://img.shields.io/badge/Swift-5-red?style=flat-square)
[![pod version](https://img.shields.io/badge/pod-v0.0.1-blue)](https://img.shields.io/badge/pod-v0.0.1-blue)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platforms](https://img.shields.io/badge/Platforms-iOS-blueviolet?style=flat-square)](https://img.shields.io/badge/Platforms-iOS-blueviolet?style=flat-square)

## Features

- [x] POST, GET, PUT, DELETE
- [x] Upload File
- [x] Upload Multipart FormData
- [x] Download File
- [x] Upload and Download Progress Closures
- [x] Authentication
- [x] Memory & Disk Caching
- [x] Retry Requests
- [x] TLS Certificate and Public Key Pinning
- [x] Network Reachability

## Requirements

### Platform
iOS

### Swift Version
5.7

## Installation

ZAP v1.0 IS STILL CURRENTLY UNDER DEVELOPMENT AND NOT AVAILABLE TO THE PUBLIC OR READY FOR PRODUCTION USE

ZAP will be available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ZAP'
```

## Instance Implementation
Every request gets its own instance so that all configurations are contained within the single request allowing for fine control and non interference with other networking tasks. Best used for granular control when complex concurrent or parallel tasks are being performed and need precise handling. This object does not need retained in memory because all cached data is stored in a singleton.

```swift
Zap()
```

Send a networking request with basic data and no files

```swift
Task {
    let result = await Zap().send(.post, url: baseURL.appending(postOnePath), success: PostOneResponseBody.self, failure: ServerError.self, body: body)
    switch result {
    case .success(let successObject): break
        // Do something with the success object
    case .failure(let errorObject): break
        // Do something with the error object
    }
}
```

Send a networking request to upload a single file

```swift
Task {
    let result = await ZAP().sendFile(.post, to: baseURL.appending(uploadFilePath), success: SuccessResponse.self, failure: ServerError.self, fileURL: path, queryItems: nil, headers: nil, cachedSuccess: nil, progress: { progress in
        // Do something with the file transfer progress
    }
}
```

Send a networking request to upload multiple files and optionally other basic data

```swift
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
```

Send a networking request to download a single file

```swift
let queryItems: [URLQueryItem] = [
    URLQueryItem(name: "age", value: "30"),
    URLQueryItem(name: "birthday", value: "04221995")
]

Task {
    let result = await ZAP().receiveFile(.get, from: baseURL.appending(postOnePath), body: nil, queryItems: queryItems, headers: nil, cachedFile: nil, progress: nil)
    switch result {
    case .success(let fileData): break
        // Do something with the success
    case .failure(let errorObject): break
        // Do something with the error
    }
}
```

## Chained Configurations

### Authentication

Automatically sets the "Authorization" header with a base 64 encoded token. Omitting the arguments will utilize global configuration default authorization credentials if present
auth(user: "", pass: "")

```swift
Task {
    let result = await ZAP()
                        .auth(token: keychain.get(AUTH_TOKEN))
                        .send(success: SuccessResponse.self, failure: ServerError.self)
}
```

### Memory Cache

Add the chained configuration cacheInMemory() to enable caching support for a specific request. The `CachedSuccess` value will return a closure with your cached response data if it is available in the memory cache.

```swift
Task {
    let result = await ZAP()
                        .cacheInMemory()
                        .send(url: baseURL.appending(postOnePath), success: SuccessResponse.self, failure: ServerError.self) { cachedSuccess in
        // Update the UI temporarily with cached data until new data is received from the server
    }
}
```

### Disk Cache

Add the chained configuration cacheOnDisk() to enable caching support for a specific request. The `CachedSuccess` value will return a closure with your cache response data if it is available on the disk cache.

```swift
Task {
    let result = await ZAP()
                        .cacheOnDisk()
                        .send(url: baseURL.appending(postOnePath), success: SuccessResponse.self, failure: ServerError.self) { cachedSuccess in
        // Update the UI temporarily with cached data until new data is received from the server
    }
}
```

## Global Configurations

Modifying these static properties allow you to have internal control on how the framework behaves. Determine how much space your caches take up, hardware resources, and more.

```swift
ZAP.memoryCacheSize = 100
ZAP.diskCacheSize = 500
ZAP.maxMemoryCacheFileSize = 5
ZAP.successStatusCodes = [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]
ZAP.defaultCachePolicy = .useProtocolCachePolicy
ZAP.defaultAuthCredentials = keychain.get(AUTH_TOKEN)
```

## Author

samuscarella, contact@muscarella.info

## License

ZAP is available under the MIT license. See the LICENSE file for more info.
