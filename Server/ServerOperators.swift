// ServerOperators.swift
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

enum RequestMiddlewareResult<RequestType, ResponseType> {

    case Request(RequestType)
    case Response(ResponseType)

}

infix operator >>> { associativity left }

func >>> <A, B, C>(f: (A -> B), g: (B -> C)) -> (A -> C) {

    return { x in g(f(x)) }
    
}

func >>> <A, B, C>(f: (A throws -> B), g: (B throws -> C)) -> (A throws -> C) {

    return { x in try g(f(x)) }

}

func >>><Request, Response>(middlewareA: (Request throws -> RequestMiddlewareResult<Request, Response>)?, middlewareB: Request throws -> RequestMiddlewareResult<Request, Response>) -> Request throws -> RequestMiddlewareResult<Request, Response> {

    if let middlewareA = middlewareA {

        return middlewareA >>> middlewareB

    }

    return middlewareB
    
}

func >>><Request, Response>(middlewareA: Request throws -> RequestMiddlewareResult<Request, Response>, middlewareB: Request throws -> RequestMiddlewareResult<Request, Response>) -> Request throws -> RequestMiddlewareResult<Request, Response> {

    return { (request: Request) -> RequestMiddlewareResult<Request, Response> in

        switch try middlewareA(request) {

        case .Request(let request):
            return try middlewareB(request)

        case .Response(let response):
            return .Response(response)

        }

    }

}

func >>><Request, Response>(middleware: (Request throws -> RequestMiddlewareResult<Request, Response>)?, respond: Request throws -> Response) -> (Request throws -> Response) {

    return { (request: Request) -> Response in

        if let middleware = middleware {

            switch try middleware(request) {

            case .Request(let request):
                return try respond(request)

            case .Response(let response):
                return response

            }

        } else {

            return try respond(request)

        }

    }

}

func >>><Response>(middlewareA: (Response throws -> Response)?, middlewareB: Response throws -> Response) -> (Response throws -> Response) {

    if let middlewareA = middlewareA {

        return middlewareA >>> middlewareB

    } else {

        return middlewareB
        
    }

}

func >>><Request, Response>(respond: Request throws -> Response, middleware: (Response throws -> Response)?) -> (Request throws -> Response) {

    return { request in

        if let middleware = middleware {

            return try middleware(respond(request))

        } else {

            return try respond(request)

        }

    }
    
}

func ??<Request, Response>(respondA: (Request throws -> Response)?, respondB: Request throws -> Response) -> (Request throws -> Response) {

    if let respondA = respondA {

        return respondA

    }

    return respondB

}

func >>><Request, Response>(respond: Request throws -> Response, respondError: ErrorType -> Response) -> ((request: Request) -> Response) {

    return { request in

        do {

            return try respond(request)

        } catch {

            return respondError(error)
            
        }
        
    }
    
}