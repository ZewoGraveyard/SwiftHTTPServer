// Server.swift
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

struct Middleware {}
struct Responder {}

struct RParser: ServerParser {

    typealias Request = HTTPRequest

    static func receiveRequest(socket socket: Socket) throws -> HTTPRequest {

        let requestLine = try getRequestLine(socket: socket)
        let headers = try HTTPParser.getHeaders(socket: socket)
        let body = try HTTPParser.getBody(socket: socket, headers: headers)

        return HTTPRequest(
            method: requestLine.method,
            URI: requestLine.URI,
            version: requestLine.version,
            headers: headers,
            body: body
        )

    }

}

// MARK: - Private

extension RParser {

    private static func getRequestLine(socket socket: Socket) throws -> HTTPRequestLine {

        let requestLine = try HTTPParser.getLine(socket: socket)
        let requestLineTokens = requestLine.splitBy(" ")

        if requestLineTokens.count != 3 {

            throw Error.Generic("Impossible to create HTTP Request", "Invalid request line")

        }

        let method = HTTPMethod(string: requestLineTokens[0])
        let URI = requestLineTokens[1]
        let version = try HTTPVersion(string: requestLineTokens[2])

        return HTTPRequestLine(
            method: method,
            URI: URI,
            version: version
        )
        
    }
    
}

struct RSerializer: ServerSerializer {

    typealias Response = HTTPResponse

    static func sendResponse(socket socket: Socket, response: HTTPResponse) throws {

        try socket.writeString("\(response.version) \(response.status.statusCode) \(response.status.reasonPhrase)\r\n")

        for (name, value) in response.headers {

            try socket.writeString("\(name): \(value)\r\n")

        }

        try socket.writeString("\r\n")

        if let data = response.body.data {

            try socket.writeData(data)
            
        }
        
    }
    
}

struct Server {

//    private let server: HTTPServer
    private let server: RServer<RParser, RSerializer>

    init() {

//        self.server = HTTPServer(
//
//            Middleware.logRequest >>> [
//
//                "/"         =| Responder.index.respond,
//                "/login"    =| Responder.login.respond,
//                "/user/:id" =| Responder.user.respond,
//                "/json"     =| Responder.json.respond,
//                "/database" =| Responder.database.respond,
//                "/redirect" =| Responder.redirect("http://www.google.com"),
//                "/routes"   =| Middleware.authenticate >>> Responder.routes.respond
//
//            ] >>> Middleware.logResponse
//
//        )
//
//        Responder.routes.server = server

        self.server = RServer(responder: Responder.index.respond) { error in

            HTTPResponse(status: .InternalServerError, body: TextBody(text: "\(error)"))

        }

    }
    
    func start() {
        
        server.start()
        
    }
    
    func stop() {
        
        server.stop()
        
    }
    
}