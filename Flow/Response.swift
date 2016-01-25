//
// Created by Anders Carlsson on 23/01/16.
// Copyright (c) 2016 CoreDev. All rights reserved.
//

import Foundation

public struct Response<T> {

    let httpResponse: NSHTTPURLResponse
    let parsedData: T?
    let rawData: NSData?

    init(httpResponse: NSHTTPURLResponse, parsedData: T? = nil, rawData: NSData? = nil) {
        self.httpResponse = httpResponse
        self.parsedData = parsedData
        self.rawData = rawData
    }

    func valueForHeader(header: String) -> String? {
        return httpResponse.allHeaderFields[header] as? String
    }
}
