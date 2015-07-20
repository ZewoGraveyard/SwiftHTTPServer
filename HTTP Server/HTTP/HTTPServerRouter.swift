// HTTPServerRouter.swift
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

class PathRouter: ServerRouter<PathServerRoute>, Respondable {

    init(methodRoutes: [String: MethodRouter]) {

        super.init(dictionary: methodRoutes)

    }

    var respond: HTTPRequest throws -> HTTPResponse {

        return getRespond(
            key: HTTPRequest.getPath,
            defaultRespond: Responder.assetAtPath
        )
        
    }

}

struct PathServerRoute: ServerRoute {

    let key: String
    let respond: HTTPRequest throws -> HTTPResponse

    private let parameterKeys: [String]
    private let regularExpression: RegularExpression

    init(key: String, respond: HTTPRequest throws -> HTTPResponse) {

        let parameterRegularExpression = try! RegularExpression(pattern: ":([[:alnum:]]+)")
        let pattern = try! parameterRegularExpression.replace(key, withTemplate: "([[:alnum:]]+)")

        self.key = key
        self.parameterKeys = try! parameterRegularExpression.groups(key)
        self.regularExpression = try! RegularExpression(pattern: "^" + pattern + "$")
        self.respond = respond

    }

    func matchesKey(key: String) -> Bool {

        return try! regularExpression.matches(key)

    }

    func parametersForKey(key: String) -> [String: String] {

        let values = try! regularExpression.groups(key)
        return dictionaryFromKeys(parameterKeys, values: values)
        
    }
    
}

class MethodRouter: ServerRouter<MethodServerRoute>, Respondable {

    var respond: HTTPRequest throws -> HTTPResponse {

        func methodNotAllowed(method: HTTPMethod)(request: HTTPRequest) throws -> HTTPResponse {

            return HTTPResponse(status: .MethodNotAllowed)

        }

        return getRespond(
            key: HTTPRequest.getMethod,
            defaultRespond: methodNotAllowed
        )
        
    }
    
}

struct MethodServerRoute: ServerRoute {

    let key: HTTPMethod
    let respond: HTTPRequest throws -> HTTPResponse


    init(key: HTTPMethod, respond: HTTPRequest throws -> HTTPResponse) {

        self.key = key
        self.respond = respond

    }

    func matchesKey(key: HTTPMethod) -> Bool {

        return self.key == key

    }

    func parametersForKey(key: HTTPMethod) -> [String: String] {

        return [:]

    }

}
