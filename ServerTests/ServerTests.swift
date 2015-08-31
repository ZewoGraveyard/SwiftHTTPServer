//
//  ServerTests.swift
//  ServerTests
//
//  Created by Paulo Faria on 8/29/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

import XCTest

class ServerTests: XCTestCase {
    
    override func setUp() {

        super.setUp()

    }
    
    func testExample() {

        let request = HTTPRequest(method: .GET, uri: URI("/api/v1/ok")!)
        let response = ExampleServer.respond(request)
        XCTAssert(response.status == .OK)

    }

    func testExample2() {

        let json: JSON = [

            "null": nil,
            "string": "Foo Bar",
            "boolean": true,
            "array": [
                "1",
                2,
                nil,
                true,
                ["1", 2, nil, false],
                ["a": "b"]
            ],
            "object": [
                "a": "1",
                "b": 2,
                "c": nil,
                "d": false,
                "e": ["1", 2, nil, false],
                "f": ["a": "b"]
            ],
            "number": 1969

        ]

        let request = HTTPRequest(method: .GET, uri: URI("/api/json")!)
        let response = ExampleServer.respond(request)
        XCTAssert(response.status == .OK)
        XCTAssert(response.equalsJSON(json))

    }

    override func tearDown() {

        super.tearDown()
        
    }

}
