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

infix operator >>> { associativity left }

func >>> <A, B, C>(f: A throws -> B, g: B throws -> C) -> A throws -> C {

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

func >>>(middleware: RequestMiddleware, responder: RequestResponder) -> RequestResponder {

    return { (request: HTTPRequest) -> HTTPResponse in

        switch try middleware(request) {

        case .Request(let request):
            return try responder(request)

        case .Response(let response):
            return response

        }

    }

}

// MARK: (RequestMiddleware, [String: RequestResponder]) -> HTTPServerConfiguration

func >>>(inMiddlewares: RequestMiddleware, routes: [String: RequestResponder]) -> HTTPServerConfiguration {

    return HTTPServerConfiguration(inMiddlewares: inMiddlewares, routes: routes)

}

// MARK: (HTTPServerConfiguration, ResponseMiddleware) -> HTTPServerConfiguration

func >>>(configuration: HTTPServerConfiguration, outMiddlewares: ResponseMiddleware) -> HTTPServerConfiguration {

    if let inMiddlewares = configuration.inMiddlewares {

        return HTTPServerConfiguration(
            inMiddlewares: inMiddlewares,
            routes: configuration.routes,
            outMiddlewares: outMiddlewares
        )

    } else {

        return HTTPServerConfiguration(
            routes: configuration.routes,
            outMiddlewares: outMiddlewares
        )

    }

}

// MARK: ([String: RequestResponder], ResponseMiddleware) -> HTTPServerConfiguration

func >>>(routes: [String: RequestResponder], outMiddlewares: ResponseMiddleware) -> HTTPServerConfiguration {

    return HTTPServerConfiguration(routes: routes, outMiddlewares: outMiddlewares)
    
}