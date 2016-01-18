//
//  Request.swift
//  Flow
//
//  Created by Anders Carlsson on 15/01/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import Foundation
import SwiftyJSON


// Default UTF8StringParser
public let UTF8StringParser: (NSData) -> (String) = {
    data in return NSString.init(data: data, encoding: NSUTF8StringEncoding) as String!
}

// Standard JSONParser
public let JSONParser: (NSData) throws -> (AnyObject) = {
    data in return try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
}

// SwiftyJSON parser
public let SwiftyJSONParser: (NSData) -> (JSON) = { data in return JSON(data: data) }

//MARK: HTTP Methods
private enum HTTPMethod: String {
    case GET, PUT, POST, DELETE
}

public final class Target {
    
    private let url: String
    private lazy var parameters: Array<NSURLQueryItem> = []
    private lazy var headers: [String:String] = [:]
    private var session: NSURLSession
    private var body: NSData?
    
    
    init(url: String, session: NSURLSession) {
        self.url = url
        self.session = session
    }
    
    // MARK: Value collector methods
    public func header(name: String, value: String) -> Self {
        headers[name] = value
        return self
    }
    
    public func headers(headers: [String:String]) -> Self {
        for (name, value) in headers {
            self.headers[name] = value
        }
        return self
    }
    
    public func parameter(name: String, value: String) -> Self {
        parameters.append(NSURLQueryItem(name: name, value: value))
        return self
    }
    
    public func parameters(parameters: [String:String]) -> Self {
        for (name, value) in parameters {
            self.parameters.append(NSURLQueryItem(name: name, value: value))
        }
        return self
    }
    
    //MARK: build methods
    
    // Defaults to JSON response parser
    public func get(callback: (Response<JSON>?, FlowError?) -> ()) -> Request {
        return get(SwiftyJSONParser, callback: callback)
    }
    
    // Custom response parser
    public func get<T>(parser: (NSData) throws -> (T), callback: (Response<T>?, FlowError?) -> ()) -> Request {
        return createRequest(createURLRequest(.GET), parser: parser, callback: callback)
    }
    
    // Defaults to String response parser
    public func post(body: NSData? = nil, callback: (Response<String>?, FlowError?) -> ()) -> Request {
        self.body = body
        return post(body, parser: UTF8StringParser, callback: callback)
    }
    
    // Custom response parser
    public func post<T>(body: NSData? = nil, parser: (NSData) throws -> (T), callback: (Response<T>?, FlowError?) -> ()) -> Request {
        self.body = body
        return createRequest(createURLRequest(.POST), parser: parser, callback: callback)
    }
    
    // Defaults to String response parser
    public func put(body: NSData? = nil, callback: (Response<String>?, FlowError?) -> ()) -> Request {
        return put(body, parser: UTF8StringParser, callback: callback)
    }
    
    // Custom response parser
    public func put<T>(body: NSData? = nil, parser: (NSData) throws -> (T), callback: (Response<T>?, FlowError?) -> ()) -> Request {
        self.body = body
        return createRequest(createURLRequest(.PUT), parser: parser, callback: callback)
    }
    
    // Defaults to String response parser
    public func delete(callback: (Response<String>?, FlowError?) -> ()) -> Request {
        return delete(UTF8StringParser, callback: callback)
    }
    
    // Custom response parser
    public func delete<T>(parser: (NSData) throws -> (T), callback: (Response<T>?, FlowError?) -> ()) -> Request {
        return createRequest(createURLRequest(.DELETE), parser: parser, callback: callback)
    }
    
    // MARK: Private helper methods
    
    private func createURLRequest(method: HTTPMethod) -> NSURLRequest {
        
        let urlComponent = NSURLComponents(string: url)!
        urlComponent.queryItems = parameters
        
        let request = NSMutableURLRequest(URL: urlComponent.URL!)
        request.allHTTPHeaderFields = headers
        request.HTTPMethod = method.rawValue
        request.HTTPBody = body
        
        return request
    }
    
    private func createRequest<T>(request: NSURLRequest, parser: (NSData) throws -> (T), callback: (Response<T>?, FlowError?) -> ()) -> Request {
        
        let sessionTask = session.dataTaskWithRequest(request) {
            data, response, error in
            
            if let httpResponse = response as? NSHTTPURLResponse where httpResponse.isSuccessResponse(), let data = data {
                Queue.background() {
                    do {
                        let parsed = try parser(data)
                        let result = Response(parsedData: parsed, rawData: data, httpResponse: httpResponse)
                        
                        Queue.main() {
                            callback(result, nil)
                        }
                        
                    } catch let parseError as NSError {
                        Queue.main() {
                            callback(nil, .ParseError(parseError))
                        }
                    }
                }
            } else {
                Queue.main() {
                    callback(nil, .ErrorResponse(error, response))
                }
            }
        }
        
        sessionTask.resume()
        
        return Request(task: sessionTask)
    }
    
}

