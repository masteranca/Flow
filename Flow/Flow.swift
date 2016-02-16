//
//  Flow.swift
//  Flow
//
//  Created by Anders Carlsson on 02/10/15.
//  Copyright © 2015 CoreDev. All rights reserved.
//

import Foundation


public func main(block: dispatch_block_t) {
    dispatch_async(dispatch_get_main_queue(), block)
}

public func background(block: dispatch_block_t) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block)
}


public final class Flow {

    private let session: NSURLSession

    public convenience init() {
        self.init(session: NSURLSession.sharedSession())
    }

    public convenience init(configuration: NSURLSessionConfiguration) {
        let session = NSURLSession(configuration: configuration)
        self.init(session: session)
    }

    public init(session: NSURLSession) {
        self.session = session
    }

    public func target(url: String) -> Target {
        return Target(url: url, session: session)
    }

    func invalidateSession() {
        self.session.invalidateAndCancel()
    }
}


public enum FlowError: ErrorType {

    case UnsupportedResponse(NSURLResponse)
    case CommunicationError(ErrorType?)
    case ClientError(NSHTTPURLResponse)
    case ServerError(NSHTTPURLResponse)
    case UnsupportedStatusCode(NSHTTPURLResponse)
    case UnknownError

}


// MARK: NSHTTPURLResponse - Extension

public extension NSHTTPURLResponse {

    public func isSuccessResponse() -> Bool {
        return (self.statusCode / 100) == 2
    }

    public func headerValueForKey(key: String) -> String? {
        return self.allHeaderFields[key] as? String
    }
}