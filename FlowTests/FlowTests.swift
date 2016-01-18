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
    
    func testGet() {
        
        let url = "http://httpbin.org/get"
        var result:Response<JSON>?
        
        let task = Flow().target(url).get(){ response, error in
            result = response
        }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: 3)
        expect(result).notTo(beNil())
        
    }
    
    func testPost() {
        
        let url = "http://httpbin.org/post"
        let payload = "1001"
        let body = "payload=\(payload)".dataUsingEncoding(NSUTF8StringEncoding)!
        var result: Response<JSON>?
        
        let task = Flow().target(url).post(body, parser: SwiftyJSONParser){ response, error in
            result = response
        }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: 3)
        expect(result?.parsedData).notTo(beNil())
        expect(result?.parsedData["form"]["payload"].string!).to(equal(payload))
    }
    
    func testParsingIsDoneOnBackgroundQueue() {
        
        let url = "http://httpbin.org/get"
        var queue: qos_class_t = qos_class_t.init(0)
        let parser:(NSData) -> (Void) = { data in queue = qos_class_self() }
        
        let task = Flow().target(url).get(parser){ response, error in }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: 3)
        expect(queue).to(equal(QOS_CLASS_BACKGROUND))
    }
    
    func testCallbackIsCalledOnMainQueue() {
        
        let url = "http://httpbin.org/get"
        var queue: qos_class_t = qos_class_t.init(0)
        let task = Flow().target(url).get(){ response, error in queue = qos_class_self() }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: 3)
        expect(queue).to(equal(qos_class_main()))
    }
}