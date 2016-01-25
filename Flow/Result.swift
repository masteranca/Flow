//
// Created by Anders Carlsson on 23/01/16.
// Copyright (c) 2016 CoreDev. All rights reserved.
//

import Foundation

public enum Result<T> {

    case Success(Response<T>?)
    case Failure(FlowError)

    public func isSuccess() -> Bool {
        switch self {
            case Success: return true
            case Failure: return false
        }
    }

    public func isFailure() -> Bool {
        return !self.isSuccess()
    }

    public var value: Response<T>? {
        switch self {
            case Success(let response): return response
            case Failure: return nil
        }
    }

    public var error: FlowError? {
        switch self {
            case Success: return nil
            case Failure(let error): return error
        }
    }
}