//
//  FlowTests.swift
//  FlowTests
//
//  Created by Anders Carlsson on 16/01/16.
//  Copyright © 2016 CoreDev. All rights reserved.
//

import XCTest
import Flow
import SwiftyJSON

class FlowTests: XCTestCase {

    private let getURL = "http://httpbin.org/get"
    private let postURL = "http://httpbin.org/post"
    private let putURL = "http://httpbin.org/put"
    private let deleteURL = "http://httpbin.org/delete"

    func testGet() {

        let expectation = expectationWithDescription("Get should be successful")
        var result: FlowResult<JSON>?

        let request = Flow().target(getURL).get() {
            response in result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertNotNil(result?.value)
    }

    func testPost() {

        let expectation = expectationWithDescription("Post should be successful")
        let payload = "1001"
        let body = "payload=\(payload)".dataUsingEncoding(NSUTF8StringEncoding)!
        var result: FlowResult<JSON>?

        let request = Flow().target(postURL).post(body, parser: SwiftyJSONParser) { response in
            result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertNotNil(result?.value)
        XCTAssertEqual(result?.value?.parsedData?["form"]["payload"].string, payload)
    }

    func testPut() {

        let expectation = expectationWithDescription("Put should be successful")
        let data = "payload".dataUsingEncoding(NSUTF8StringEncoding)
        var result: FlowResult<JSON>?

        let request = Flow().target(putURL).put(data, parser: SwiftyJSONParser) { response in
            result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertNotNil(result?.value)
        XCTAssertEqual(result?.value?.parsedData?["data"].string, "payload")
    }

    func testDelete() {

        let expectation = expectationWithDescription("Delete should be successful")
        var result: FlowResult<String>?

        let request = Flow().target(deleteURL).delete(){ response in
            result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
    }

    func testSingleQueryParameter() {
        let expectation = expectationWithDescription("Added query parameter should be returned")
        var result: FlowResult<JSON>?

        let request = Flow().target(getURL).parameter("name", value:"value").get(){ response in
            result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertEqual(result?.value?.parsedData?["args"]["name"].string, "value")
    }

    func testMultipleQueryParamaters(){
        let expectation = expectationWithDescription("Added query parameters should be returned")
        let parameters = ["name1":"value1", "name2":"value2"]
        var result: FlowResult<JSON>?

        let request = Flow().target(getURL).parameters(parameters).get(){ response in
            result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertEqual(result?.value?.parsedData?["args"]["name1"], "value1")
        XCTAssertEqual(result?.value?.parsedData?["args"]["name2"], "value2")
    }


    func testSingleHeader() {

        let expectation = expectationWithDescription("Added header should be returned")
        var result: FlowResult<JSON>?

        let request = Flow().target(getURL).header("Api-Key", value: "12345").get() {
            response in result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertNotNil(result?.value)
        XCTAssertEqual(result?.value?.parsedData?["headers"]["Api-Key"].string, "12345")
    }

    func testMultipleHeaders() {

        let expectation = expectationWithDescription("Added headers should be returned")
        let headers = ["Key1": "Value1", "Key2": "Value2"]
        var result: FlowResult<JSON>?

        let request = Flow().target(getURL).headers(headers).get() {
            response in result = response
            expectation.fulfill()
        }

        waitForExpectation()

        assertSuccessRequest(request, result: result)
        XCTAssertEqual(result?.value?.parsedData?["headers"]["Key1"].string, "Value1")
        XCTAssertEqual(result?.value?.parsedData?["headers"]["Key2"].string, "Value2")
    }

    func testParsingIsDoneOnBackgroundQueue() {

        let expectation = expectationWithDescription("Parsing should be done on a background thread")
        var queue: qos_class_t = qos_class_t.init(0)
        let parser: (NSData?) -> (Void) = { data in queue = qos_class_self() }

        let request = Flow().target(getURL).get(parser) { response in expectation.fulfill() }

        waitForExpectation()

        XCTAssertTrue(request.isFinished)
        XCTAssertEqual(QOS_CLASS_BACKGROUND, queue)
    }

    func testCallbackIsCalledOnMainQueue() {

        let expectation = expectationWithDescription("Callback should be done on main thread")
        var queue: qos_class_t = qos_class_t.init(0)
        let request = Flow().target(getURL).get() {
            response in queue = qos_class_self()
            expectation.fulfill()
        }

        waitForExpectation()

        XCTAssertTrue(request.isFinished)
        XCTAssertEqual(qos_class_main(), queue)
    }

    //MARK: Helper methods
    func assertSuccessRequest<T>(request: FlowRequest, result: FlowResult<T>?) {
        XCTAssertTrue(request.isFinished)
        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertTrue(result.isSuccess())
        } else {
            XCTFail("Result should be successful")
        }
    }

    func waitForExpectation(){
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
}