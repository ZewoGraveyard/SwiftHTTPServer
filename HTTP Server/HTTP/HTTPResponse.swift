// HTTPResponse.swift
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

struct HTTPResponse {

    let status: HTTPStatus
    let headers: [String: String]
    let body: HTTPBody

    init(status: HTTPStatus, var headers: [String: String] = [:], body: HTTPBody = EmptyBody()) {

        headers = HTTPResponse.headersByAddingContentTypeFromBody(body, toHeaders: headers)
        // TODO: Think about the name of the server
        headers = HTTPResponse.headersByAddingServer("Server", toHeaders: headers)

        self.status = status
        self.headers = headers
        self.body = body

    }

    func responseByAddingHeaders(headers: [String: String]) -> HTTPResponse {

        return HTTPResponse(
            status: self.status,
            headers: self.headers + headers,
            body: self.body
        )
        
    }

    static func headersByAddingContentTypeFromBody(body: HTTPBody, var toHeaders headers: [String: String]) -> [String: String] {

        if let contentType = body.contentType {
        
            headers["content-type"] = "\(contentType)"
        
        }

        if let data = body.data {

            headers["content-length"] = "\(data.length)"

        } else {

            headers["content-length"] = "0"

        }

        return headers

    }

    static func headersByAddingServer(server: String, var toHeaders headers: [String: String]) -> [String: String] {

        headers["server"] = server
        return headers
        
    }

}

extension HTTPResponse: CustomStringConvertible {

    var description: String {

        var string = "\(status.statusCode) \(status.reasonPhrase) \(status.HTTPVersion)\n"

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

extension HTTPResponse: CustomColorLogStringConvertible {

    var logDescription: String {

        var string = Log.lightPurple
        
        string += "\(status.statusCode) \(status.reasonPhrase) \(status.HTTPVersion)\n"

        string += Log.darkPurple

        for (index, (header, value)) in headers.enumerate() {

            string += "  \(header): \(value)"

            if index != headers.count - 1 {

                string += "\n"

            }

        }

        string += Log.purple

        if let body = body.data {

            string += "\n\(body)"
            
        }

        string += Log.reset
        
        return string
        
    }
    
}
