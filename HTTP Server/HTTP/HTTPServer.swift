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

final class HTTPServer {

    private var router = HTTPRouter()
    private var socket: Socket?

    var routes: [String] {

        return router.routes.map { $0.path }

    }

}

// MARK: - Public

extension HTTPServer {

    func route(path: String, responder: HTTPRequest throws -> HTTPResponse) {

        let simpleResponder = HTTPSimpleRequestResponder(responder: responder)
        router.addRoute(path, responder: simpleResponder)

    }

    func route(path: String, responder: HTTPRequestResponder) {

        router.addRoute(path, responder: responder)
        
    }

    func start(port port: TCPPort = 8080, failure: ErrorType -> Void = HTTPServer.defaultFailure)   {

        do {

            socket?.release()
            socket = try Socket(port: port, maxConnections: 1000)

            Log.info("HTTP Server connected at port \(port).")

            Dispatch.async(queue: backgroundQueue) {

                self.waitForClients(failure)

            }

        } catch {

            failure(error)

        }

    }

}

// MARK: - Private

extension HTTPServer {

    private static func defaultFailure(error: ErrorType) {

        Log.error("Server error: \(error)")
        
    }

    private func waitForClients(failure: ErrorType -> Void) {

        do {

            while true {

                let clientSocket = try socket!.acceptClient()

                Dispatch.async(queue: backgroundQueue) {

                    self.processClientSocket(clientSocket, failure: failure)

                }

            }

        } catch {

            socket?.release()
            failure(error)
            
        }

    }

    private func processClientSocket(clientSocket: Socket, failure: ErrorType -> Void) {

        do {

            while true {

                let request = try HTTPServerParser.receiveHTTPRequest(clientSocket)

                Log.info(request)

                try processRequest(request, clientSocket: clientSocket, failure: failure)

                if request.keepAlive == false {

                    break
                    
                }

            }

            clientSocket.release()

        } catch {

            failure(error)

        }

    }

    private func processRequest(request: HTTPRequest, clientSocket: Socket, failure: ErrorType -> Void) throws {

        var response: HTTPResponse

        if let routeMatch = router.match(request.path) {

            response = responseForRouteMatch(routeMatch, request: request, failure: failure)

        } else {

            response = responseForAssetAtPath(request.path)

        }

        if request.keepAlive {

            response = response.responseByAddingHeaders(["Connection": "keep-alive"])

        }

        Log.info(response)

        try HTTPServerSerializer.sendHTTPResponse(clientSocket, response: response)

    }

    private func responseForRouteMatch(routeMatch: HTTPRouter.RouteMatch, var request: HTTPRequest, failure: ErrorType -> Void) -> HTTPResponse {

        let pathParameters = routeMatch.pathParameters
        let responder = routeMatch.responder

        request.pathParameters = pathParameters

        do {

            return try responder.respondRequest(request)

        } catch {

            failure(error)
            return HTTPResponse(status: .InternalServerError, body: TextBody(text: "\(error)"))

        }
        
    }

    private func responseForAssetAtPath(path: String) -> HTTPResponse {

        let assetPath = path.dropFirstCharacter()

        if let asset = Asset(path: assetPath) {

            return HTTPResponse(status: .OK, body: DataBody(asset: asset))

        } else {

            return HTTPResponse(status: .NotFound)
            
        }

    }

}

