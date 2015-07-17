// HTTPRequest.swift
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

struct HTTPRequest: ServerRoutable {

    let method: HTTPMethod
    let URI: String
    let version: HTTPVersion
    let headers: [String: String]
    let body: HTTPBody
    let parameters: [String: String]

    init(
        method: HTTPMethod,
        URI: String,
        version: HTTPVersion = .HTTP_1_1,
        headers: [String: String] = [:],
        body: HTTPBody = EmptyBody(),
        parameters: [String: String] = [:]) {

        self.method = method
        self.URI = URI
        self.version = version
        self.headers = headers
        self.body = body
        self.parameters = parameters

    }

    func copyWithParameters(parameters: [String: String]) -> HTTPRequest {

        return HTTPRequest(
            method:     self.method,
            URI:        self.URI,
            version:    self.version,
            headers:    self.headers,
            body:       self.body,
            parameters: self.parameters + parameters
        )

    }

}

extension HTTPRequest: CustomStringConvertible {

    var description: String {

        var string = "\(method) \(URI) HTTP/1.1\n"

        for (index, (header, value)) in headers.enumerate() {

            string += "  \(header): \(value)"

            if index != headers.count - 1 {

                string += "\n"

            }

        }

        if let body = body.data {

            string += "\n\(body)"

        }

        return string

    }

}

extension HTTPRequest: CustomColorLogStringConvertible {

    var logDescription: String {

        var string = Log.lightGreen

        string += "\(method) \(URI) HTTP/1.1\n"

        string += Log.darkGreen

        for (index, (header, value)) in headers.enumerate() {

            string += "  \(header): \(value)"

            if index != headers.count - 1 {

                string += "\n"

            }

        }

        string += Log.green

        if let body = body.data {
            
            string += "\n\(body)"
            
        }

        string += Log.reset
        
        return string
        
    }
    
}