// HTTPServerParser.swift
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

struct HTTPRequestParser2 {

    func parseRequest(socket socket: Socket) throws -> HTTPRequest {

        struct RawHTTPRequest {
            var method: String = ""
            var uri: String = ""
            var version: String = ""
            var currentHeaderField: String = ""
            var headers: [String: String] = [:]
            var body: [Int8] = []
        }

        func onURL(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            let requestPointer = UnsafeMutablePointer<RawHTTPRequest>(parser.memory.data)

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            requestPointer.memory.uri = String.fromCString(buffer)!

            return 0

        }

        func onHeaderField(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            let requestPointer = UnsafeMutablePointer<RawHTTPRequest>(parser.memory.data)

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            requestPointer.memory.currentHeaderField = String.fromCString(buffer)!
            
            return 0

        }

        func onHeaderValue(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            let requestPointer = UnsafeMutablePointer<RawHTTPRequest>(parser.memory.data)

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            let headerField = requestPointer.memory.currentHeaderField.lowercaseString
            requestPointer.memory.headers[headerField] = String.fromCString(buffer)!

            return 0

        }

        func onHeadersComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {

            let requestPointer = UnsafeMutablePointer<RawHTTPRequest>(parser.memory.data)

            let method = http_method_str(http_method(parser.memory.method))
            requestPointer.memory.method = String.fromCString(method)!

            let major = parser.memory.http_major
            let minor = parser.memory.http_minor

            requestPointer.memory.version = "HTTP/\(major).\(minor)"

            return 0

        }

        func onBody(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
            
            let requestPointer = UnsafeMutablePointer<RawHTTPRequest>(parser.memory.data)

            var buffer: [Int8] = [Int8](count: length, repeatedValue: 0)
            memcpy(&buffer, data, length)

            requestPointer.memory.body = buffer
            
            return 0
            
        }

        var settings = http_parser_settings(
            on_message_begin: nil,
            on_url: onURL,
            on_status: nil,
            on_header_field: onHeaderField,
            on_header_value: onHeaderValue,
            on_headers_complete: onHeadersComplete,
            on_body: onBody,
            on_message_complete: nil
        )

        var parser = http_parser()

        http_parser_init(&parser, HTTP_REQUEST)

        var request = RawHTTPRequest()

        let requestPointer = UnsafeMutablePointer<RawHTTPRequest>.alloc(1)
        requestPointer.initialize(request)

        parser.data = UnsafeMutablePointer<Void>(requestPointer)

        var (buffer, bytesRead) = try socket.receiveBuffer(bufferSize: 80 * 1024)

        let bytesParsed = http_parser_execute(&parser, &settings, &buffer, bytesRead)

        if parser.upgrade == 1 {

            /* handle new protocol */

        }

        if bytesParsed != bytesRead {

            let error = http_errno_name(http_errno(parser.http_errno))
            throw Error.Generic("Error parsing request",  String.fromCString(error)!)

        }

        request = requestPointer.memory

        requestPointer.destroy()
        requestPointer.dealloc(1)

        guard let uri = URI(text: request.uri) else {

            throw Error.Generic("Error parsing URI", "Invalid URI")

        }

        if uri.path == nil {

            throw Error.Generic("Error parsing URI", "Path not present")
            
        }

        return HTTPRequest(
            method: HTTPMethod(string: request.method),
            uri: uri,
            version: try HTTPVersion(string: request.version),
            headers: request.headers,
            body: Data(bytes: request.body)
        )

    }

}
