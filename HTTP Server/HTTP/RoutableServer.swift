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

class RoutableServer<Parser: RequestParser, Serializer: ResponseSerializer where Parser.Request: ServerRoutable>: Server<Parser, Serializer> {

    let routes: [String]

    init(requestMiddlewares: (Parser.Request throws -> RequestMiddlewareResult<Parser.Request, Serializer.Response>)? = nil,
        routes: [ServerRoute<Parser.Request, Serializer.Response>] = [],
        responseMiddlewares: ((request: Parser.Request) -> (Serializer.Response throws -> Serializer.Response))? = nil,
        defaultResponder: (path: String) -> (Parser.Request throws -> Serializer.Response),
        failureResponder: (error: ErrorType) -> Serializer.Response,
        keepConnectionForRequest: ((request: Parser.Request) -> Bool)? = nil) {

            let router = ServerRouter.responderForRoutes(routes: routes)

            let responderForRequest = { (request: Parser.Request) -> (Parser.Request -> Serializer.Response) in

                return requestMiddlewares >>>
                       router(path: request.path) ?? defaultResponder(path: request.path) >>>
                       responseMiddlewares?(request: request) >>>
                       failureResponder

            }

            self.routes = routes.map { $0.path }

            super.init(
                responderForRequest: responderForRequest,
                keepConnectionForRequest: keepConnectionForRequest
            )

    }

}