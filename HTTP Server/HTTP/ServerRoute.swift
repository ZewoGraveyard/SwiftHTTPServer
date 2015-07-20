// ServerRoute.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

protocol ServerRoute {

    typealias Key: Hashable
    typealias Request
    typealias Response

    var key: Key { get }
    var responder: Request throws -> Response { get }

    init(key: Key, responder: Request throws -> Response)
    func matchesKey(key: Key) -> Bool
    func parametersForKey(key: Key) -> [String: String]
    
}

struct MethodServerRoute<Request, Response>: ServerRoute {

    let key: HTTPMethod
    let responder: Request throws -> Response


    init(key: HTTPMethod, responder: Request throws -> Response) {

        self.key = key
        self.responder = responder

    }

    func matchesKey(key: HTTPMethod) -> Bool {

        return self.key == key

    }

    func parametersForKey(key: HTTPMethod) -> [String: String] {

        return [:]
        
    }
    
}


struct PathServerRoute<Request, Response>: ServerRoute {

    let key: String
    let responder: Request throws -> Response

    private let parameterKeys: [String]
    private let regularExpression: RegularExpression

    init(key: String, responder: Request throws -> Response) {

        let parameterRegularExpression = try! RegularExpression(pattern: ":([[:alnum:]]+)")
        let pattern = try! parameterRegularExpression.replace(key, withTemplate: "([[:alnum:]]+)")

        self.key = key
        self.parameterKeys = try! parameterRegularExpression.groups(key)
        self.regularExpression = try! RegularExpression(pattern: "^" + pattern + "$")
        self.responder = responder

    }

    func matchesKey(key: String) -> Bool {

        return try! regularExpression.matches(key)

    }

    func parametersForKey(key: String) -> [String: String] {

        let values = try! regularExpression.groups(key)
        return dictionaryFromKeys(parameterKeys, values: values)

    }

}
