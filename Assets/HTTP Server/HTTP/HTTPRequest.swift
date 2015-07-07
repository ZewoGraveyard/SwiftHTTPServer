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

struct HTTPRequest {

    let method: HTTPMethod
    let URI: String
    let headers: [String: String]
    let body: HTTPBody

    var pathParameters: [String: String]
    let queryParameters: [String: String]

    init(method: String, URI: String, headers: [String: String], body: Data?, pathParameters: [String: String] = [:]) throws {

        self.method = HTTPMethod(string: method)
        self.URI = URI
        self.headers = headers
        self.body = try HTTPRequest.bodyFromData(body, headers: headers)
        self.pathParameters = pathParameters
        self.queryParameters = HTTPRequest.queryParametersFromURI(URI)

    }

    var path: String {

        return URI.splitBy("?").first!

    }

    var keepAlive: Bool {

        if let value = headers["connection"] {

            return "keep-alive" == value.trim().lowercaseString

        }
        
        return false
        
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

extension HTTPRequest {

    private static func bodyFromData(data: Data?, headers: [String: String]) throws -> HTTPBody {

        guard let data = data
        else { return EmptyBody() }

        guard let contentType = headers["content-type"]
        else { return DataBody(data: data) }

        let mediaType = InternetMediaType(string: contentType)

        switch mediaType {

        case .ApplicationJSON:
            return try JSONBody(data: data)

        case .ApplicationXWWWFormURLEncoded:
            return try FormURLEncodedBody(data: data)

        case .MultipartFormData(let boundary):
            return MultipartFormDataBody(data: data, boundary: boundary)

        case .TextPlain:
            return try TextBody(data: data)

        case (let contentType):
            return DataBody(data: data, contentType: contentType)

        }
        
    }

    private static func queryParametersFromURI(path: String) -> [String: String] {

        if let query = path.splitBy("?").last {

            return query.queryParameters

        }
        
        return [:]
        
    }
    
}
