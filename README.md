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

ZAP is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ZAP'
```

## Instance Implementation (Recommended)
Every request gets its own instance so that all configurations are contained within the single request allowing for fine control and non interference with other networking tasks. Best used for granular control when complex concurrent or parallel tasks are being performed and need precise handling. This object does not need retained in memory because all cached data is stored in a singleton.

```swift
Task {
    let result = await Zap()    .send(.post, url: baseURL.appending(postOnePath), success: PostOneResponseBody.self, failure: ServerError.self, body: body)
    switch result {
    case .success(let success): break
        // Do something with the success result
    case .failure(let error): break
        // Do something with the error result
    }
}
```

Send a networking request with basic data and no files

```swift
```

Send a networking request to upload a single file

```swift
```

Send a networking request to upload multiple files and optionally other basic data

```swift
```

Send a networking request to download a single file

```swift
```

## Authentication

Automatically sets the "Authorization" header with a base 64 encoded token. Omitting the arguments will utilize global configuration default authorization credentials if present
auth(user: "", pass: "")

## Memory & Disk Caching

Add the chained configuration cacheInMemory() to enable caching support for a specific request. The `CachedSuccess` value will return a closure with your cached response data if it is available in the memory cache.

```swift
```

Add the chained configuration cacheOnDisk() to enable caching support for a specific request. The `CachedSuccess` value will return a closure with your cache response data if it is available in the disk cache.

```swift
```

## Global Configurations

Modifying these static properties allow you to have internal control on how the framework behaves. Determine how much space your caches take up hardware resources and more.

## Author

samuscarella, contact@muscarella.info

## License

ZAP is available under the MIT license. See the LICENSE file for more info.
