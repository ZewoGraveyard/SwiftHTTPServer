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

func defaultFailureHandler(error: ErrorType) {

    Log.error("Server error: \(error)")

}

protocol RequestType {

    var keepAlive: Bool { get }

}

protocol ServerParser {

    typealias Request: RequestType
    static func receiveRequest(socket socket: Socket) throws -> Request

}

protocol ServerSerializer {

    typealias Response
    static func sendResponse(socket socket: Socket, response: Response) throws

}

final class RServer<Parser: ServerParser, Serializer: ServerSerializer> {

    private let responder: Parser.Request throws -> Serializer.Response
    private let failureResponse: ErrorType -> Serializer.Response
    private var socket: Socket?

    init(responder: Parser.Request throws -> Serializer.Response, failureResponse: ErrorType -> Serializer.Response) {

        self.responder = responder
        self.failureResponse = failureResponse

    }

}

// MARK: - Start / Stop

extension RServer {

    func start(port port: TCPPort = 8080, failureHandler: ErrorType -> Void = defaultFailureHandler)   {

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

extension RServer {

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

                let responderChain = responder >>> failureHandler >>> failureResponse

                let response = responderChain(request)
                
                try Serializer.sendResponse(socket: clientSocket, response: response)
                
                if !request.keepAlive { break }
                
            }
            
            clientSocket.release()
            
        } catch {
            
            failureHandler(error)
            
        }
        
    }
    
}

func >>><Request, Response>(responder: Request throws -> Response, failureHandler: ErrorType -> Void)(failureResponse: ErrorType -> Response) -> (Request -> Response) {

    return { request in

        do {

            return try responder(request)

        } catch {

            failureHandler(error)
            return failureResponse(error)
            
        }
        
    }
    
}

func >>><Request, Response>(responder: (ErrorType -> Response) -> (Request -> Response), failureResponse: ErrorType -> Response) -> (Request -> Response) {

    return responder(failureResponse)

}