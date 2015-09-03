// ResourcefulResponder.swift
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

protocol ResourcefulResponder {

    func index(request: HTTPRequest) throws -> HTTPResponse
    func create(request: HTTPRequest) throws -> HTTPResponse
    func show(request: HTTPRequest) throws -> HTTPResponse
    func update(request: HTTPRequest) throws -> HTTPResponse
    func destroy(request: HTTPRequest) throws -> HTTPResponse

}

extension ResourcefulResponder {

    func index(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .MethodNotAllowed)

    }

    func create(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .MethodNotAllowed)

    }

    func show(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .MethodNotAllowed)

    }

    func update(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .MethodNotAllowed)

    }

    func destroy(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .MethodNotAllowed)

    }

}

struct SimpleResourcefulResponder: ResourcefulResponder {

    let indexFunction: (request: HTTPRequest) throws -> HTTPResponse
    let createFunction: (request: HTTPRequest) throws -> HTTPResponse
    let showFunction: (request: HTTPRequest) throws -> HTTPResponse
    let updateFunction: (request: HTTPRequest) throws -> HTTPResponse
    let destroyFunction: (request: HTTPRequest) throws -> HTTPResponse

    func index(request: HTTPRequest) throws -> HTTPResponse {

        return try self.indexFunction(request: request)

    }

    func create(request: HTTPRequest) throws -> HTTPResponse {

        return try self.createFunction(request: request)

    }

    func show(request: HTTPRequest) throws -> HTTPResponse {

        return try self.showFunction(request: request)

    }

    func update(request: HTTPRequest) throws -> HTTPResponse {

        return try self.updateFunction(request: request)

    }

    func destroy(request: HTTPRequest) throws -> HTTPResponse {

        return try self.destroyFunction(request: request)

    }

}

func >>><T: ResourcefulResponder>(middleware: HTTPRequest throws -> RequestMiddlewareResult<HTTPRequest, HTTPResponse>, responder: T) -> SimpleResourcefulResponder {

    return SimpleResourcefulResponder(
        indexFunction:   middleware >>> responder.index,
        createFunction:  middleware >>> responder.create,
        showFunction:    middleware >>> responder.show,
        updateFunction:  middleware >>> responder.update,
        destroyFunction: middleware >>> responder.destroy
    )

}

func >>><T: ResourcefulResponder>(responder: T, middleware: HTTPResponse throws -> HTTPResponse) -> SimpleResourcefulResponder {

    return SimpleResourcefulResponder(
        indexFunction:   responder.index   >>> middleware,
        createFunction:  responder.create  >>> middleware,
        showFunction:    responder.show    >>> middleware,
        updateFunction:  responder.update  >>> middleware,
        destroyFunction: responder.destroy >>> middleware
    )
    
}