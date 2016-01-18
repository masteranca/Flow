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

// MARK: FlowError

public enum FlowError: ErrorType {

    case CommunicationError(NSError?, NSURLResponse?)
    case ErrorResponse(NSError?, NSURLResponse?)
    case ParseError(NSError?)
}


// MARK: NSHTTPURLResponse - Extenstion

public extension NSHTTPURLResponse {

    public func isSuccessResponse() -> Bool {
        return (self.statusCode / 100) == 2
    }
}