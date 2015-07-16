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

    private let requestMiddlewares: RequestMiddleware?
    private let router: (path: String) -> RequestResponder?
    private let responseMiddlewares: ResponseMiddleware?
    private var socket: Socket?

    let routes: [String]

    init(requestMiddlewares: RequestMiddleware? = nil,
        routes: [HTTPRoute] = [],
        responseMiddlewares: ResponseMiddleware? = nil) {

        self.requestMiddlewares = requestMiddlewares
        self.router = HTTPRouter.routes(routes)
        self.responseMiddlewares = responseMiddlewares
        self.routes = routes.map { $0.path }

    }

    convenience init(_ configuration: HTTPServerConfiguration) {

        self.init(
            requestMiddlewares: configuration.requestMiddlewares,
            routes: configuration.routes,
            responseMiddlewares: configuration.responseMiddlewares
        )

    }

    convenience init(_ requestMiddlewares: RequestMiddleware) {

        self.init(requestMiddlewares: requestMiddlewares)

    }

    convenience init(_ routes: [HTTPRoute] = []) {

        self.init(routes: routes)
        
    }

    convenience init(_ responseMiddlewares: ResponseMiddleware) {

        self.init(responseMiddlewares: responseMiddlewares)

    }

}

// MARK: - Start / Stop

extension HTTPServer {

    func start(port port: TCPPort = 8080, failureHandler: ErrorType -> Void = HTTPServer.defaultFailureHandler)   {

        do {

            socket?.release()
            socket = try Socket(port: port, maxConnections: 1000)

            Log.info("HTTP Server listening at port \(port).")

            Dispatch.async {

                self.waitForClients(failureHandler: failureHandler)

            }

        } catch {

            failureHandler(error)

        }

    }

    func stop() {

        socket?.release()

    }

}

// MARK: - Private

extension HTTPServer {

    private static func defaultFailureHandler(error: ErrorType) {

        Log.error("Server error: \(error)")
        
    }

    private func waitForClients(failureHandler failureHandler: ErrorType -> Void) {

        do {

            while true {

                let clientSocket = try socket!.acceptClient()

                Dispatch.async {

                    self.processClientSocket(clientSocket, failureHandler: failureHandler)

                }

            }

        } catch {

            socket?.release()
            failureHandler(error)
            
        }

    }

    private func processClientSocket(clientSocket: Socket, failureHandler: ErrorType -> Void) {

        do {

            while true {

                let request =  try HTTPServerParser.receiveHTTPRequest(socket: clientSocket)

                let responder = requestMiddlewares >>>
                                router(path: request.path) ?? Responder.assetAtPath(request.path) >>>
                                responseMiddlewares >>>
                                Middleware.keepAlive(request.keepAlive) >>>
                                Middleware.headers(["server": "HTTP Server"]) >>>
                                failureHandler

                let response = responder(request)

                try HTTPServerSerializer.sendHTTPResponse(socket: clientSocket, response: response)

                if !request.keepAlive { break }

            }

            clientSocket.release()

        } catch {

            failureHandler(error)

        }

    }

}