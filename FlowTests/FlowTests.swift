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
        var response:Result<JSON>?
        
        let task = Flow().target(url).get(){ result in
            response = result
        }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: defaultTimeout)
        expect(response).notTo(beNil())
        expect(response!.isSuccess()).to(beTrue())
    }
    
    func testPost() {
        
        let url = "http://httpbin.org/post"
        let payload = "1001"
        let body = "payload=\(payload)".dataUsingEncoding(NSUTF8StringEncoding)!
        var response: Result<JSON>?
        
        let task = Flow().target(url).post(body, parser: SwiftyJSONParser){ result in
            response = result
        }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: defaultTimeout)
        expect(response).notTo(beNil())
        expect(response!.isSuccess()).to(beTrue())
        
        switch response! {
        case .Success(let json,_): expect(json?["form"]["payload"].string!).to(equal(payload))
        default: fail()
        }
    }
    
    func testParsingIsDoneOnBackgroundQueue() {
        
        let url = "http://httpbin.org/get"
        var queue: qos_class_t = qos_class_t.init(0)
        let parser:(NSData) -> (Void) = { data in queue = qos_class_self() }
        
        let task = Flow().target(url).get(parser){ result in }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: defaultTimeout)
        expect(queue).to(equal(QOS_CLASS_BACKGROUND))
    }
    
    func testCallbackIsCalledOnMainQueue() {
        
        let url = "http://httpbin.org/get"
        var queue: qos_class_t = qos_class_t.init(0)
        let task = Flow().target(url).get(){ result in queue = qos_class_self() }
        
        expect(task.isFinished).toEventually(beTrue(), timeout: defaultTimeout)
        expect(queue).to(equal(qos_class_main()))
    }
}