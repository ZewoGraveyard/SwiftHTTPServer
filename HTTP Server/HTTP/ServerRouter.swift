// ServerRouter.swift
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


typealias PathServerRouter = ServerRouter<PathServerRoute<HTTPRequest, HTTPResponse>>
typealias MethodServerRouter = ServerRouter<MethodServerRoute<HTTPRequest, HTTPResponse>>

class ServerRouter<Route: ServerRoute>: DictionaryLiteralConvertible {

    let routes: [Route]
    let keys: [Route.Key]

    init(routes: [Route]) {

        self.routes = routes
        self.keys = routes.map { $0.key }

    }

    init(dictionary: [Route.Key: Route.Request throws -> Route.Response]) {

        var routes: [Route] = []

        for (key, responder) in dictionary {

            let route = Route(key: key, responder: responder)
            routes.append(route)

        }

        self.routes = routes
        self.keys = routes.map { $0.key }
        
    }

    convenience required init(dictionaryLiteral responders: (Route.Key, Route.Request throws -> Route.Response)...) {

        var routes: [Route] = []

        for (key, responder) in responders {

            let route = Route(key: key, responder: responder)
            routes.append(route)

        }

        self.init(routes: routes)

    }

    private var routerResponder: (key: Route.Key) -> (Route.Request throws -> Route.Response)? {

        return { (key: Route.Key) in

            if let route = self.routes.find({$0.matchesKey(key)}) {

                let parameters = route.parametersForKey(key)
                return Middleware.parameters(parameters) >>> route.responder

            }

            return nil

        }

    }

    func getResponder(key key: Route.Request -> () -> Route.Key,
        defaultResponder: (key: Route.Key) -> (Route.Request throws -> Route.Response)) -> (Route.Request throws -> Route.Response) {

            return { (request: Route.Request) in

                let key = key(request)()
                let responder = self.routerResponder(key: key) ?? defaultResponder(key: key)
                return try responder(request)
                
            }
            
    }

}