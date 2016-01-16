//
//  Response.swift
//  Flow
//
//  Created by Anders Carlsson on 15/01/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import Foundation

public struct Response<T> {
    
    let parsedData: T
    let rawData: NSData
    let httpResponse: NSHTTPURLResponse
    
    var statusCode: Int {
        return httpResponse.statusCode
    }
    
    var headers: [String:String] {
        var values: [String:String] = [:]
        
        for (key, value) in httpResponse.allHeaderFields {
            values[key as! String] = value as? String
        }
        
        return values
    }
    
    public init(parsedData: T, rawData: NSData, httpResponse: NSHTTPURLResponse) {
        self.parsedData = parsedData
        self.rawData = rawData
        self.httpResponse = httpResponse
    }
}