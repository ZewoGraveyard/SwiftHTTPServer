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

protocol RequestResponseServer {

    typealias Request
    typealias Response

    var runLoop: RunLoop { get }
    var acceptTCPClient: (port: TCPPort, handleClient: (client: Stream) -> Void) throws -> Void { get }
    var parseRequest: (stream: Stream, completion: Request -> Void) -> Void { get }
    var respond: (request: Request) -> Response { get }
    var serializeResponse: (stream: Stream, response: Response) -> Void { get }

}

extension RequestResponseServer {

    func start(port port: TCPPort = 8080, failure: ErrorType -> Void = Error.defaultFailureHandler) {

        do {

            try acceptTCPClient(port: port) { client in

                self.parseRequest(stream: client) { request in

                    let keepAlive = self.keepAliveRequest(request)
                    let respond = self.respond >>> self.keepAliveResponse(keepAlive: keepAlive)
                    let response = respond(request)
                    self.serializeResponse(stream: client, response: response)

                    if !keepAlive { client.close() }

                }

            }

            runLoop.run()

        } catch {

            failure(error)

        }

    }

    func stop() {

        runLoop.close()

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