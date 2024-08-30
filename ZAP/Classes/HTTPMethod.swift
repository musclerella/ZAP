//
//  HTTPVerb.swift
//  ZAP
//
//  Created by Stephen Muscarella on 8/27/24.
//

import Foundation

enum HTTPMethod: String {
    case post
    case get
    case put
    case delete
}


//POST The POST method submits an entity to the specified resource, often causing a change in state or side effects on the server.
//GET The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
//PUT The PUT method replaces all current representations of the target resource with the request payload.
//DELETE The DELETE method deletes the specified resource.

//PATCH The PATCH method applies partial modifications to a resource.
//CONNECT The CONNECT method establishes a tunnel to the server identified by the target resource.
//OPTIONS The OPTIONS method describes the communication options for the target resource.
//TRACE The TRACE method performs a message loop-back test along the path to the target resource.
//HEAD The HEAD method asks for a response identical to a GET request, but without the response body.
