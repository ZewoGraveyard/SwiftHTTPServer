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

class Server2<Request, Response> {

    let parseRequest: (stream: Stream, completion: Request -> Void) -> Void
    let respond: (request: Request) -> Response
    let serializeResponse: (stream: Stream, response: Response) -> Void

    init(parseRequest: (stream: Stream, completion: Request -> Void) -> Void,
        respond: (request: Request) -> Response,
        serializeResponse: (stream: Stream, response: Response) -> Void,
        debug: Bool = false) {

            self.parseRequest = parseRequest
            self.respond = respond
            self.serializeResponse = serializeResponse

    }

    func start(port port: Int = 8080, failure: ErrorType -> Void = Error.defaultFailureHandler) {

        do {

            Log.info("Listening.")

            try runTCPServer(port: port) { client in

                Log.info("Connected to client.")

                self.parseRequest(stream: client) { request in

                    let keepAlive = self.keepAliveRequest(request)
                    let respond = self.respond >>> self.keepAliveResponse(keepAlive: keepAlive)
                    let response = respond(request)
                    self.serializeResponse(stream: client, response: response)

                    if !keepAlive {

                        client.closeAndFree()
                        Log.info("Closed connection with client.")
                        
                    }

                }

            }

        } catch {

            failure(error)

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