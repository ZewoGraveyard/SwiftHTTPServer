// SimpleHTTPRequestParser.swift
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

struct SimpleHTTPRequestParser {

    struct HTTPRequestLine {

        let method: HTTPMethod
        let uri: URI
        let version: String
        
    }

    static func parseRequest(socket socket: Socket) throws -> HTTPRequest {

        let requestLine = try getRequestLine(socket: socket)
        let headers = try SimpleHTTPParser.getHeaders(socket: socket)
        let body = try SimpleHTTPParser.getBody(socket: socket, headers: headers)

        return HTTPRequest(
            method: requestLine.method,
            uri: requestLine.uri,
            version: requestLine.version,
            headers: headers,
            body: body
        )

    }

    private static func getRequestLine(socket socket: Socket) throws -> HTTPRequestLine {

        let requestLine = try SimpleHTTPParser.getLine(socket: socket)
        let requestLineTokens = requestLine.splitBy(" ")

        if requestLineTokens.count != 3 {

            throw Error.Generic("Impossible to create HTTP Request", "Invalid request line")

        }

        let method = HTTPMethod(string: requestLineTokens[0])

        guard let uri = URI(text: requestLineTokens[1]) else {

            throw Error.Generic("Impossible to create HTTP Request", "Invalid request line")

        }

        let version = requestLineTokens[2]

        return HTTPRequestLine(
            method: method,
            uri: uri,
            version: version
        )
        
    }
    
}
