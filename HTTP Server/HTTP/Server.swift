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

protocol KeepAliveType {

    var keepAlive: Bool { get set }
    
}

class Server<Request, Response> {

    let parseRequest: (socket: Socket) throws -> Request
    let respond: (request: Request) -> Response
    let serializeResponse: (socket: Socket, response: Response) throws -> Void
    var socket: Socket?

    let debug: Bool

    init(parseRequest: (socket: Socket) throws -> Request,
        respond: (request: Request) -> Response,
        serializeResponse: (socket: Socket, response: Response) throws -> Void,
        debug: Bool = false) {

            self.parseRequest = parseRequest
            self.respond = respond
            self.serializeResponse = serializeResponse
            self.debug = debug

    }

    func start(port port: TCPPort = 8080, failure: ErrorType -> Void = Error.defaultFailureHandler) {

        do {

            try startListening(port: port)
            Dispatch.async(queue: backgroundQueue) { self.waitForClients(port: port, failure: failure) }
            if debug { Log.info("Server listening at \(socket!.IP):\(socket!.port).") }

        } catch {

            failure(error)
            
        }
        
    }

    func stop() {

        socket?.release()

    }

}

// MARK: - Private

extension Server {

    private func startListening(port port: TCPPort) throws {

        socket?.release()
        socket = try Socket(port: port, maxConnections: 1000)

    }

    private func waitForClients(port port: TCPPort, failure: ErrorType -> Void) {

        while true {

            do {

                while true {

                    let clientSocket = try socket!.acceptClient()
                    Dispatch.async(queue: backgroundQueue) { self.processClient(clientSocket: clientSocket, failure: failure) }
                    if debug { Log.info("Connected to client at \(clientSocket.IP):\(clientSocket.port).") }

                }

            } catch {

                failure(error)

            }

            // TODO: Think about this
            try! startListening(port: port)

        }

    }

    private func processClient(clientSocket clientSocket: Socket, failure: ErrorType -> Void) {

        do {

            while true {

                let request = try self.parseRequest(socket: clientSocket)
                let keepAlive = keepAliveRequest(request)
                let respond = self.respond >>> keepAliveResponse(keepAlive: keepAlive)
                let response = respond(request)
                try self.serializeResponse(socket: clientSocket, response: response)
                if !keepAlive { break }

            }

        } catch {

            failure(error)
            
        }

        clientSocket.release()
        if debug { Log.info("Closed connection with client at \(clientSocket.IP):\(clientSocket.port).") }
        
    }
    
    private func keepAliveRequest(request: Request) -> Bool {
        
        return (request as? KeepAliveType)?.keepAlive ?? false
        
    }

    private func keepAliveResponse<Response>(keepAlive keepAlive: Bool) -> (Response -> Response) {

        return { response in

            if var response = response as? KeepAliveType {

                response.keepAlive = keepAlive
                return response as! Response

            } else {

                return response
                
            }

        }
        
    }
    
}