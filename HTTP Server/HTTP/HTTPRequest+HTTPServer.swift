// HTTPRequest+HTTPServer.swift
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

extension HTTPRequest {

    var path: String {

        return URI.splitBy("?").first!

    }
    
}

extension HTTPRequest {

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

extension HTTPRequest {

    var queryParameters: [String: String] {

        if let query = URI.splitBy("?").last {

            return query.queryParameters

        }

        return [:]

    }

}

extension HTTPRequest {

    var keepConnection: Bool {

        if let value = headers["connection"] {

            return "keep-alive" == value.trim().lowercaseString
            
        }
        
        return false
        
    }
    
}