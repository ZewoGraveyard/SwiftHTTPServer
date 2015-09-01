// FastCGIServer.swift
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

var environment: [String: String] {

    var envs: [String: String] = [:]

    for (var env = environ; env.memory != nil; ++env) {

        let envString = String.fromCString(env.memory)!
        let index = envString.characters.indexOf("=")!
        let name = envString.substringToIndex(index)
        let value = envString.substringFromIndex(index.advancedBy(1))

        envs[name] = value

    }

    return envs

}

func getRequest() -> HTTPRequest? {

    let env = environment

    func getHeaders() -> [String: String] {

        var headers: [String: String] = [:]

        let HTTPHeaders = env.filter { $0.0.hasPrefix("HTTP_") }

        for (key, value) in HTTPHeaders {

            let index = key.characters.indexOf("_")!
            let name = key.substringFromIndex(index.advancedBy(1)).lowercaseString.replaceOccurrencesOfString("_", withString: "-")

            headers[name] = value

        }

        return headers

    }

    func getBody() -> Data {

        if let contentLenghtString = env["CONTENT_LENGTH"], contentLenght = Int(contentLenghtString) {

            var buffer: [UInt8] = [UInt8](count: contentLenght, repeatedValue: 0)
            FCGI_readBuffer(&buffer, contentLenght)
            return Data(bytes: buffer)

        }

        return Data()

    }

    if let method = env["REQUEST_METHOD"], uriString = env["REQUEST_URI"], uri = URI(uriString), version = env["SERVER_PROTOCOL"] {

        return HTTPRequest(
            method: HTTPMethod(string: method),
            uri: uri,
            version: version,
            headers: getHeaders(),
            body: getBody()
        )

    }

    return nil

}

func sendResponse(var response: HTTPResponse) {

    if response.headers["content-type"] == nil {

        response.headers["content-type"] = ""

    }

    FCGI_writeString("Status: \(response.status.statusCode) \(response.status.reasonPhrase)\r\n")

    for (name, value) in response.headers {

        FCGI_writeString("\(name): \(value)\r\n")

    }

    FCGI_writeString("\r\n")

    FCGI_writeBuffer(UnsafeMutablePointer<Void>(response.body.bytes), response.body.length)

}

class FastCGIServer {

    let respond: (request: HTTPRequest) -> HTTPResponse

    init(respond: (request: HTTPRequest) -> HTTPResponse) {

        self.respond = respond >>> Middleware.addHeaders(["server": "HTTP Server"])

    }

    func start() {

        while(FCGI_Accept() >= 0) {
            
            if let request = getRequest() {
                
                let response = respond(request: request)
                sendResponse(response)

            }
            
        }
        
    }
    
}