// HTTPRequestParser.swift
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

    func parseRequest(stream stream: Stream, completion: HTTPRequest -> Void) {

        struct RawHTTPRequest {
            var method: String = ""
            var uri: String = ""
            var version: String = ""
            var currentHeaderField: String = ""
            var headers: [String: String] = [:]
            var body: [Int8] = []
        }

        var request = RawHTTPRequest()

        func onURL(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            request.uri = String.fromCString(buffer)!

            return 0

        }

        func onHeaderField(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            request.currentHeaderField = String.fromCString(buffer)!

            return 0

        }

        func onHeaderValue(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            var buffer: [Int8] = [Int8](count: length + 1, repeatedValue: 0)
            strncpy(&buffer, data, length)

            let headerField = request.currentHeaderField.lowercaseString
            request.headers[headerField] = String.fromCString(buffer)!

            return 0

        }

        func onHeadersComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {

            let method = http_method_str(http_method(parser.memory.method))
            request.method = String.fromCString(method)!

            let major = parser.memory.http_major
            let minor = parser.memory.http_minor

            request.version = "HTTP/\(major).\(minor)"

            return 0

        }

        func onBody(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {

            var buffer: [Int8] = [Int8](count: length, repeatedValue: 0)
            memcpy(&buffer, data, length)

            request.body = buffer

            return 0

        }

        func onMessageComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {


            guard let uri = URI(request.uri) else {

                print("Error parsing URI. Invalid URI")
                return -1

            }

            let request = HTTPRequest(
                method: HTTPMethod(string: request.method),
                uri: uri,
                version: request.version,
                headers: request.headers,
                body: Data(bytes: request.body)
            )

            completion(request)

            return 0

        }

        var parser = http_parser()

        http_parser_init(&parser, HTTP_REQUEST)

        try! stream.bufferedRead { data in

            let bytesParsed = http_parser_execute(
                &parser,
                nil,
                onURL,
                nil,
                onHeaderField,
                onHeaderValue,
                onHeadersComplete,
                onBody,
                onMessageComplete,
                UnsafePointer<Int8>(data.bytes),
                data.length
            )
            
            if parser.upgrade == 1 {
                
                print("Error parsing request: Protocol upgrade unsupported")
                
            }
            
            if bytesParsed != data.length {
                
                let error = http_errno_name(http_errno(parser.http_errno))
                print("Error parsing request: " + String.fromCString(error)!)
                
            }
            
        }
        
    }
    
}
