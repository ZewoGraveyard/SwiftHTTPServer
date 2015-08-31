// HTTPPathRouter.swift
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

final class HTTPPathRouter: ServerRouter<HTTPPathRoute> {

    let fallback: (path: String) -> HTTPRequest throws -> HTTPResponse

    init(fallback: (path: String) -> HTTPRequest throws -> HTTPResponse) {

        self.fallback = fallback

    }

    var respond: HTTPRequest throws -> HTTPResponse {

        return getRespond(
            key: HTTPRequest.pathRouterKey,
            fallback: fallback
        )

    }

}

struct HTTPPathRoute: ServerRoute {

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

    var respondForKey: (key: String) -> (HTTPRequest throws -> HTTPResponse) {

        return { (key: String) in

            let values = try! self.regularExpression.groups(key)
            let parameters = try! dictionaryFromKeys(self.parameterKeys, values: values)
            return Middleware.addParameters(parameters) >>> self.respond
            
        }
        
    }
    
}