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

class Server<Parser: RequestParser, Serializer: ResponseSerializer> {

    let responderForRequest: (request: Parser.Request) -> (Parser.Request throws -> Serializer.Response)
    let failureResponder: (error: ErrorType) -> Serializer.Response

    var socket: Socket?

    init(responderForRequest: (request: Parser.Request) -> (Parser.Request throws -> Serializer.Response),
        failureResponder: (error: ErrorType) -> Serializer.Response) {

            self.responderForRequest = responderForRequest
            self.failureResponder = failureResponder

    }

    func start(port port: TCPPort = 8080, failureHandler: ErrorType -> Void = Error.defaultFailureHandler)   {

        do {

            socket?.release()
            socket = try Socket(port: port, maxConnections: 1000)
            Dispatch.async { self.waitForClients(failureHandler: failureHandler) }
            Log.info("Server listening at port \(port).")

        } catch {

            failureHandler(error)

        }

    }

    func stop() {

        socket?.release()

    }

}

// MARK: - Private

extension Server {

    private func waitForClients(failureHandler failureHandler: ErrorType -> Void) {

        do {

            while true {

                let clientSocket = try socket!.acceptClient()
                Dispatch.async { self.processClient(clientSocket: clientSocket, failureHandler: failureHandler) }

            }

        } catch {

            socket?.release()
            failureHandler(error)

        }

    }

    private func processClient(clientSocket clientSocket: Socket, failureHandler: ErrorType -> Void) {

        do {

            while true {

                let request = try Parser.receiveRequest(socket: clientSocket)
                let respond = responderForRequest(request: request) >>>
                              failureResponder >>>
                              Middleware.keepConnection(request: request)
                let response = respond(request)
                try Serializer.sendResponse(socket: clientSocket, response: response)

                if !keepConnectionForRequest(request) { break }

            }

            clientSocket.release()

        } catch {
            
            failureHandler(error)
            
        }
        
    }
    
    private func keepConnectionForRequest(request: Parser.Request) -> Bool {
        
        return (request as? KeepConnectionRequest)?.keepConnection ?? false
        
    }
    
}