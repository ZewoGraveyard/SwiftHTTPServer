// HTTPServerRouter.swift
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

struct HTTPMethodRouter {

    let routes: [HTTPMethodRoute]

    init(responders: [HTTPMethod: HTTPRequest throws -> HTTPResponse]) {

        var routes: [HTTPMethodRoute] = []

        for (method, responder) in responders {

            let route = HTTPMethodRoute(method: method, responder: responder)
            routes.append(route)
            
        }

        self.routes = routes

    }

    var responder: (HTTPRequest throws -> HTTPResponse) {

        return { (request: HTTPRequest) in

            if let route = self.routes.find({$0.method == request.method}) {

                return try route.responder(request)

            }
            
            return HTTPResponse(status: .MethodNotAllowed)
            
        }
        
    }

}

struct HTTPMethodRoute {

    let method: HTTPMethod
    let responder: HTTPRequest throws -> HTTPResponse
    
}

struct HTTPServerRouter: DictionaryLiteralConvertible {

    let router: ServerRouter<HTTPRequest, HTTPResponse>

    init(dictionaryLiteral methodResponders: (String, Dictionary<HTTPMethod, (HTTPRequest) throws -> HTTPResponse>)...) {

        var routes: [ServerRoute<HTTPRequest, HTTPResponse>] = []

        for (path, methodResponder) in methodResponders {

            let methodRouter = HTTPMethodRouter(responders: methodResponder)
            let route = ServerRoute(path: path, responder: methodRouter.responder)
            routes.append(route)

        }

        self.router = ServerRouter(routes: routes)

    }

}