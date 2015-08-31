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

    let parseRequest: (socket: Socket, completion: Request -> Void) -> Void
    let respond: (request: Request) -> Response
    let serializeResponse: (socket: Socket, response: Response) throws -> Void
    var socket: Socket?

    init(parseRequest: (socket: Socket, completion: Request -> Void) -> Void,
        respond: (request: Request) -> Response,
        serializeResponse: (socket: Socket, response: Response) throws -> Void) {

            self.parseRequest = parseRequest
            self.respond = respond
            self.serializeResponse = serializeResponse

    }

    func start(port port: TCPPort = 8080, failure: ErrorType -> Void = Error.defaultFailureHandler) {

        do {

            socket?.release()
            socket = try Socket(port: port, maxConnections: 128)
            Dispatch.async(queue: Dispatch.backgroundQueue) { self.waitForClients(port: port, failure: failure) }
            Dispatch.main()

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

    private func waitForClients(port port: TCPPort, failure: ErrorType -> Void) {

        do {

            while true {

                let clientSocket = try socket!.acceptClient()
                Dispatch.async(queue: Dispatch.backgroundQueue) { self.processClient(clientSocket: clientSocket, failure: failure) }

            }

        } catch {

            failure(error)

        }

    }

    private func processClient(clientSocket clientSocket: Socket, failure: ErrorType -> Void) {

        self.parseRequest(socket: clientSocket) { request in

            let keepAlive = self.keepAliveRequest(request)
            let respond = self.respond >>> self.keepAliveResponse(keepAlive: keepAlive)
            let response = respond(request)
            try! self.serializeResponse(socket: clientSocket, response: response)

            if !keepAlive {

                clientSocket.release()

            }

        }

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