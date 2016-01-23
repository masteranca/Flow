//
//  FlowRequest.swift
//  Flow
//
//  Created by Anders Carlsson on 15/01/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import Foundation
import SwiftyJSON


// Default UTF8StringParser
public let UTF8StringParser: (NSData?) -> (String?) = {
    data in if let data = data {
        return NSString.init(data: data, encoding: NSUTF8StringEncoding) as String!
    } else {
        return nil
    }
}

// Standard JSONParser
public let JSONParser: (NSData?) -> (AnyObject?) = {
    data in if let data = data {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
        } catch {
            return nil
        }
    } else {
        return nil
    }
}

// SwiftyJSON parser
public let SwiftyJSONParser: (NSData?) -> (JSON?) = {
    data in if let data = data {
        return JSON(data: data)
    } else {
        return nil
    }
}

//MARK: HTTP Methods

private enum HTTPMethod: String {
    case GET, PUT, POST, DELETE
}

public final class FlowTarget {

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
    public func header(name: String, value: String) -> FlowTarget {
        headers[name] = value
        return self
    }

    public func headers(headers: [String:String]) -> FlowTarget {
        for (name, value) in headers {
            self.headers[name] = value
        }
        return self
    }

    public func parameter(name: String, value: String) -> FlowTarget {
        parameters.append(NSURLQueryItem(name: name, value: value))
        return self
    }

    public func parameters(parameters: [String:String]) -> FlowTarget {
        for (name, value) in parameters {
            self.parameters.append(NSURLQueryItem(name: name, value: value))
        }
        return self
    }

    //TODO: add authorization

    //MARK: request methods

    // Defaults to SwiftyJSON response parser
    public func get(callback: (FlowResult<JSON>?) -> ()) -> FlowRequest {
        return get(SwiftyJSONParser, callback: callback)
    }

    // Custom response parser
    public func get<T>(parser: (NSData?) -> (T?), callback: (FlowResult<T>?) -> ()) -> FlowRequest {
        return request(httpMethod(.GET), parser: parser, callback: callback)
    }

    // Defaults to UTF8StringParser response parser
    public func post(body: NSData? = nil, callback: (FlowResult<String>?) -> ()) -> FlowRequest {
        self.body = body
        return post(body, parser: UTF8StringParser, callback: callback)
    }

    // Custom response parser
    public func post<T>(body: NSData? = nil, parser: (NSData?) -> (T?), callback: (FlowResult<T>?) -> ()) -> FlowRequest {
        self.body = body
        return request(httpMethod(.POST), parser: parser, callback: callback)
    }

    // Defaults to UTF8StringParser response parser
    public func put(body: NSData? = nil, callback: (FlowResult<String>?) -> ()) -> FlowRequest {
        return put(body, parser: UTF8StringParser, callback: callback)
    }

    // Custom response parser
    public func put<T>(body: NSData? = nil, parser: (NSData?) -> (T?), callback: (FlowResult<T>?) -> ()) -> FlowRequest {
        self.body = body
        return request(httpMethod(.PUT), parser: parser, callback: callback)
    }

    // Defaults to UTF8StringParser response parser
    public func delete(callback: (FlowResult<String>?) -> ()) -> FlowRequest {
        return delete(UTF8StringParser, callback: callback)
    }

    // Custom response parser
    public func delete<T>(parser: (NSData?) -> (T?), callback: (FlowResult<T>?) -> ()) -> FlowRequest {
        return request(httpMethod(.DELETE), parser: parser, callback: callback)
    }

    // MARK: Private helper methods

    private func httpMethod(method: HTTPMethod) -> NSURLRequest {

        let urlComponent = NSURLComponents(string: url)!
        urlComponent.queryItems = parameters

        let request = NSMutableURLRequest(URL: urlComponent.URL!)
        request.allHTTPHeaderFields = headers
        request.HTTPMethod = method.rawValue
        request.HTTPBody = body

        return request
    }

    private func request<T>(request: NSURLRequest, parser: (NSData?) -> (T?), callback: (FlowResult<T>?) -> ()) -> FlowRequest {

        let sessionTask = session.dataTaskWithRequest(request) { data, response, error in

            if let error = error {
                callback(.Failure(.CommunicationError(error)))
            } else {
                if let httpResponse = response as? NSHTTPURLResponse where httpResponse.isSuccessResponse() {
                    Queue.background() {
                        let parsed = parser(data)
                        Queue.main() {
                            callback(.Success(FlowResponse(httpResponse: httpResponse, parsedData: parsed, rawData: data)))
                        }
                    }
                } else {
                    callback(.Failure(self.errorFromResponse(response)))
                }
            }
        }

        sessionTask.resume()

        return FlowRequest(task: sessionTask)
    }

    private func errorFromResponse(response: NSURLResponse?) -> FlowError {
        if let response = response {
            if let httpResponse = response as? NSHTTPURLResponse {
                switch (httpResponse.statusCode / 100) {
                    case 1, 3: return .UnsupportedStatusCode(httpResponse)
                    case 4: return .ClientError(httpResponse)
                    case 5: return .ServerError(httpResponse)
                    default: return .UnknownError
                }
            }
            return .UnsupportedResponse(response)
        } else {
            return .UnknownError
        }
    }
}

