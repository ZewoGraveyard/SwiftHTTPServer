// HTTPMethodMiddleware.swift
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

protocol HTTPMethodMiddleware: HTTPRequestMiddlewareType {

    func any(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func get(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func head(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func post(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func put(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func delete(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func trace(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func options(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func connect(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func patch(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult
    func unrecognizedMethod(method: String, request: HTTPRequest) throws -> HTTPRequestMiddlewareResult

}

extension HTTPMethodMiddleware {

    func any(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return .Request(request)

    }

    func get(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func head(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)
        
    }

    func post(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }
    
    func put(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func delete(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func trace(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func options(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func connect(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func patch(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

    func unrecognizedMethod(method: String, request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        return try any(request)

    }

}

extension HTTPMethodMiddleware {

    func mediate(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        switch request.method {

        case .GET: return try get(request)
        case .HEAD: return try head(request)
        case .POST: return try post(request)
        case .PUT: return try put(request)
        case .DELETE: return try delete(request)
        case .TRACE: return try trace(request)
        case .OPTIONS: return try options(request)
        case .CONNECT: return try connect(request)
        case .PATCH: return try patch(request)
        case .Unrecognized(let method): return try unrecognizedMethod(method, request: request)

        }

    }

}