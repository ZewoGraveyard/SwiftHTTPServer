// HTTPServer.swift
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

/**
HTTPServer parses HTTPRequest from the client and passes it to the respond function. The respond function returns
an HTTPResponse which is serialized by the HTTPServer and sent back to the client.
*/
struct HTTPServer : Server {

    let runLoop: RunLoop = FakeRunLoop()
    let acceptTCPClient = acceptClient
    let parseRequest = HTTPRequestParser.parseRequest
    let respond: HTTPRequest -> HTTPResponse
    let serializeResponse = HTTPResponseSerializer.serializeResponse

    /**
    Initializes an HTTPServer with a function that receives an HTTPRequest and returns an HTTPResponse.
    
    Below we have an example of a simple respond function that always returns an HTTPResponse with status 200 OK.
    
        let respond = { (request: HTTPRequest) in

            return HTTPResponse(status: .OK)

        }
    
        let server = HTTPServer(respond: respond)
        server.start()

    The most common way to create a respond function is through an HTTPRouter. Because the HTTPRouter can throw errors
    we have to associate it with a function that can turns an error into an HTTPResponse.
    
    The framework provides HTTPError.respondError but you can write your own function if you wish. We associate
    HTTPRouter with HTTPError.respondError through the >>> operator.
    
        let respond = HTTPRouter { router in

            router.get("/ok") { (request: HTTPRequest) in

                return HTTPResponse(status: .OK)
    
            }
    
            router.get("/fail") { (request: HTTPRequest) in

                return HTTPResponse(status: .BadRequest)

            }

        } >>> HTTPError.respondError
    
        let server = HTTPServer(respond: respond)
        server.start()
    
    - parameter respond: function that turns an HTTPRequest into an HTTPResponse
    - returns: HTTPServer
    */
    init(respond: HTTPRequest -> HTTPResponse) {

        self.respond = respond >>> Middleware.keepAlive >>> Middleware.addHeaders(["server": "HTTP Server"])

    }
    
}