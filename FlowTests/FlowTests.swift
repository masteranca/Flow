//
//  FlowTests.swift
//  FlowTests
//
//  Created by Anders Carlsson on 16/01/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import XCTest
import Nimble
import Flow
import SwiftyJSON

class FlowTests: XCTestCase {

    private let defaultTimeout = 10.0


    func testGet() {
        let url = "http://httpbin.org/get"
        let expectation = expectationWithDescription("Get should be succesful for url: \(url)")
        var result: FlowResult<JSON>?

        let task = Flow().target(url).get() {
            response in result = response
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(defaultTimeout, handler: nil)

        XCTAssertTrue(task.isFinished)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isSuccess())
        XCTAssertNotNil(result!.value)
    }

    func testPost() {
        let url = "http://httpbin.org/post"
        let expectation = expectationWithDescription("Post should be succesful for url: \(url)")
        let payload = "1001"
        let body = "payload=\(payload)".dataUsingEncoding(NSUTF8StringEncoding)!
        var result: FlowResult<JSON>?

        let task = Flow().target(url).post(body, parser: SwiftyJSONParser) { response in
            result = response
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(defaultTimeout, handler: nil)

        XCTAssertTrue(task.isFinished)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isSuccess())
        XCTAssertNotNil(result!.value)
        XCTAssertEqual(result!.value!.parsedData!["form"]["payload"].string!, payload)
    }

    func testParsingIsDoneOnBackgroundQueue() {

        let url = "http://httpbin.org/get"
        let expectation = expectationWithDescription("Parsing should be done on a background thread")
        var queue: qos_class_t = qos_class_t.init(0)
        let parser:(NSData?) -> (Void) = { data in queue = qos_class_self() }

        let task = Flow().target(url).get(parser){ response in expectation.fulfill() }

        waitForExpectationsWithTimeout(defaultTimeout, handler: nil)

        XCTAssertTrue(task.isFinished)
        XCTAssertEqual(QOS_CLASS_BACKGROUND, queue)
    }

    func testCallbackIsCalledOnMainQueue() {

        let url = "http://httpbin.org/get"
        let expectation = expectationWithDescription("Callback should be done on main thread")
        var queue: qos_class_t = qos_class_t.init(0)
        let task = Flow().target(url).get(){ response in
            queue = qos_class_self()
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(defaultTimeout, handler: nil)

        XCTAssertTrue(task.isFinished)
        XCTAssertEqual(qos_class_main(), queue)
    }
}