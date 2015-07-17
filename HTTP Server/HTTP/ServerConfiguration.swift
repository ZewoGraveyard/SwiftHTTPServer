// ServerConfiguration.swift
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

struct RouteConfiguration<Request, Response where Request: ServerRoutable> {

    typealias Route = ServerRoute<Request, Response>
    typealias RequestMiddleware = Request throws -> RequestMiddlewareResult<Request, Response>
    typealias ResponseMiddleware = (request: Request) -> (Response throws -> Response)

    typealias Responder = (request: Request) -> Response
    typealias DefaultResponder = (path: String) -> (Request throws -> Response)
    typealias FailureResponder = (error: ErrorType) -> Response

    typealias ResponderForRequest = (request: Request) -> Responder
    typealias KeepConnectionForRequest = (request: Request) -> Bool

    let responderForRequest: ResponderForRequest
    let keepConnectionForRequest: KeepConnectionForRequest?

    let routes: [String]

    init(requestMiddlewares: RequestMiddleware? = nil,
        routes: [Route] = [],
        responseMiddlewares: ResponseMiddleware? = nil,
        defaultResponder: DefaultResponder,
        failureResponder: FailureResponder,
        keepConnectionForRequest: KeepConnectionForRequest? = nil) {

        let router = ServerRouter.responderForRoutes(routes: routes)

        self.responderForRequest = { (request: Request) -> Responder in

            return requestMiddlewares >>>
                   router(path: request.path) ?? defaultResponder(path: request.path) >>>
                   responseMiddlewares?(request: request) >>>
                   failureResponder
            
        }

        self.keepConnectionForRequest = keepConnectionForRequest
        self.routes = routes.map { $0.path }

    }

}