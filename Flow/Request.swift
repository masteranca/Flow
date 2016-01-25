//
// Created by Anders Carlsson on 14/01/16.
// Copyright (c) 2016 CoreDev. All rights reserved.
//

import Foundation

public final class Request {

    private let task: NSURLSessionTask

    public var isRunning: Bool {
        return task.state == NSURLSessionTaskState.Running
    }

    public var isFinished: Bool {
        return task.state == NSURLSessionTaskState.Completed
    }

    public var isCanceling: Bool {
        return task.state == NSURLSessionTaskState.Canceling
    }

    init(task: NSURLSessionTask) {
        self.task = task
    }

    public func cancel() -> Request {
        task.cancel()
        return self
    }
}