// HTTPServerOperators.swift
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

typealias RequestMiddleware = HTTPRequest throws -> HTTPRequestMiddlewareResult
typealias RequestResponder = HTTPRequest throws -> HTTPResponse
typealias ResponseMiddleware = HTTPResponse throws -> HTTPResponse


infix operator =| { associativity right precedence 80 }

// MARK: (RequestMiddleware, RequestMiddleware) -> RequestMiddleware

func =|(path: String, responder: RequestResponder) -> HTTPRoute {

    return HTTPRoute(path: path, responder: responder)
    
}

infix operator >>> { associativity left }

func >>> <A, B, C>(f: (A throws -> B), g: (B throws -> C)) -> (A throws -> C) {

    return { x in try g(f(x)) }

}

// MARK: (RequestMiddleware, RequestMiddleware) -> RequestMiddleware

func >>>(middlewareA: RequestMiddleware, middlewareB: RequestMiddleware) -> RequestMiddleware {

    return { (request: HTTPRequest) -> HTTPRequestMiddlewareResult in

        switch try middlewareA(request) {

        case .Request(let request):
            return try middlewareB(request)

        case .Response(let response):
            return .Response(response)

        }

    }

}

// MARK: (RequestMiddleware, RequestResponder) -> RequestResponder

func >>>(middleware: RequestMiddleware?, responder: RequestResponder) -> RequestResponder {

    return { (request: HTTPRequest) -> HTTPResponse in

        if let middleware = middleware {

            switch try middleware(request) {

            case .Request(let request):
                return try responder(request)

            case .Response(let response):
                return response

            }

        } else {

            return try responder(request)

        }

    }

}

// MARK: (RequestResponder, ResponseMiddleware) -> RequestResponder

func >>>(responder: RequestResponder, middleware: ResponseMiddleware?) -> RequestResponder {

    return { request in

        if let middleware = middleware {

            return try middleware(responder(request))

        } else {

            return try responder(request)

        }

    }
    
}

// MARK: (RequestMiddleware, [String: RequestResponder]) -> HTTPServerConfiguration

func >>>(requestMiddlewares: RequestMiddleware, responseMiddlewares: ResponseMiddleware) -> HTTPServerConfiguration {

    return HTTPServerConfiguration(requestMiddlewares: requestMiddlewares, responseMiddlewares: responseMiddlewares)
    
}

// MARK: (RequestMiddleware, [String: RequestResponder]) -> HTTPServerConfiguration

func >>>(requestMiddlewares: RequestMiddleware, routes: [HTTPRoute]) -> HTTPServerConfiguration {

    return HTTPServerConfiguration(requestMiddlewares: requestMiddlewares, routes: routes)

}

// MARK: (HTTPServerConfiguration, ResponseMiddleware) -> HTTPServerConfiguration

func >>>(configuration: HTTPServerConfiguration, responseMiddlewares: ResponseMiddleware) -> HTTPServerConfiguration {

    if let requestMiddlewares = configuration.requestMiddlewares {

        return HTTPServerConfiguration(
            requestMiddlewares: requestMiddlewares,
            routes: configuration.routes,
            responseMiddlewares: responseMiddlewares
        )

    } else {

        return HTTPServerConfiguration(
            routes: configuration.routes,
            responseMiddlewares: responseMiddlewares
        )

    }

}

// MARK: ([String: RequestResponder], ResponseMiddleware) -> HTTPServerConfiguration

func >>>(routes: [HTTPRoute], responseMiddlewares: ResponseMiddleware) -> HTTPServerConfiguration {

    return HTTPServerConfiguration(routes: routes, responseMiddlewares: responseMiddlewares)
    
}

// MARK: (RequestResponder, ErrorType -> Void) -> (HTTPRequest -> HTTPResponse)

func >>>(responder: RequestResponder, failureHandler: ErrorType -> Void) -> (HTTPRequest -> HTTPResponse) {

    return { request in

        do {

            return try responder(request)

        } catch {

            failureHandler(error)
            return HTTPResponse(status: .InternalServerError, body: TextBody(text: "\(error)"))

        }
        
    }
        
}

// MARK: 


func ??(responderA: RequestResponder?, responderB: RequestResponder) -> RequestResponder {

    if let responder = responderA {

        return responder

    }

    return responderB

}

