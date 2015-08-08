// SimpeHTTPResponseParser.swift
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

struct SimpleHTTPResponseParser {

    struct HTTPStatusLine {

        let status: HTTPStatus
        let version: HTTPVersion
        
    }
    
    static func parseResponse(socket: Socket) throws -> HTTPResponse {
        
        let statusLine = try getStatusLine(socket: socket)
        let headers = try HTTPParser.getHeaders(socket: socket)
        let body = try HTTPParser.getBody(socket: socket, headers: headers)
        
        return HTTPResponse(
            status: statusLine.status,
            version: statusLine.version,
            headers: headers,
            body: body
        )
        
    }
    
    private static func getStatusLine(socket socket: Socket) throws -> HTTPStatusLine {
        
        let statusLine = try HTTPParser.getLine(socket: socket)
        let statusLineTokens = statusLine.splitBy(" ")

        let version = try HTTPVersion(string: statusLineTokens[0])
        
        guard let statusCode = Int(statusLineTokens[1]) else {

            throw Error.Generic("Impossible to create HTTP Request", "Invalid status code \(statusLineTokens[1])")

        }
        
        let reasonPhrase = " ".join(statusLineTokens[2 ..< statusLineTokens.count])
        
        let status = HTTPStatus(statusCode: statusCode, reasonPhrase: reasonPhrase)

        return HTTPStatusLine(
            status: status,
            version: version
        )
        
    }

}