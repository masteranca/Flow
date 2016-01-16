//
//  Flow.swift
//  Flow
//
//  Created by Anders Carlsson on 02/10/15.
//  Copyright © 2015 CoreDev. All rights reserved.
//

import Foundation

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

public enum Result<T> {

    case Success(T?, NSHTTPURLResponse)
    case CommunicationError(ErrorType?)
    case UnsupportedResponse(NSURLResponse?)
    case ParseError(ErrorType?)
    case ClientError(NSHTTPURLResponse)
    case ServerError(NSHTTPURLResponse)
    case UnsupportedStatusCode(NSHTTPURLResponse)

    public func isSuccess() -> Bool {
        switch self {
            case .Success: return true
            default: return false
        }
    }
}


// MARK: NSHTTPURLResponse - Extenstion

public extension NSHTTPURLResponse {

    public func isSuccessResponse() -> Bool {
        return (self.statusCode / 100) == 2
    }

    public func headerValueForKey(key: String) -> String {
        return self.allHeaderFields[key] as! String
    }
}