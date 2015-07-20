// ExampleServer.swift
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

struct HTTPRouter {

    var processRequest: HTTPRequestMiddleware?
    var processResponse: HTTPResponseMiddleware?

    var routes: [String: MethodRouter] = [:]

    var paths: [String] {

        return routes.keys.array
        
    }

    var respond: HTTPRequest throws -> HTTPResponse {

        let pathRouter = PathRouter()

        // WARNING: Because of the nature of dictionaries (unordered), if a path matches more than one route. The route that is chosen is undefined. It could be any of them.
        for (path, methodRouter) in routes {

            pathRouter.route(path, respond: methodRouter.respond)

        }

        return processRequest >>>
               pathRouter.respond >>>
               processResponse

    }

    mutating func pre(processRequest: HTTPRequestMiddleware) {

        self.processRequest = self.processRequest >>> processRequest

    }

    mutating func post(processResponse: HTTPResponseMiddleware) {

        self.processResponse = self.processResponse >>> processResponse

    }

    mutating func route(method: HTTPMethod, _ path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

        route([method], path, respond)
        
    }

    mutating func route(methods: Set<HTTPMethod>, _ path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

        if routes[path] == nil {

            routes[path] = MethodRouter()

        }

        for method in methods {

            routes[path]?.route(method, respond: respond)

        }

    }

    mutating func route(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

        route([.GET, .POST, .PUT, .PATCH, .DELETE], path, respond)
        
    }

}



class ExampleServer: HTTPServer {

    init() {

        var router = HTTPRouter()

        router.pre(Middleware.logRequest)

        router.route(.GET, "/login", LoginResponder.get)
        router.route(.POST, "/login", LoginResponder.post)

        router.route(.GET, "/users/", UserResponder.index)
        router.route(.POST, "/users/", UserResponder.create)

        router.route(.GET, "/users/:id/", UserResponder.show)
        router.route(.PATCH, "/users/:id/", UserResponder.update)
        router.route(.PUT, "/users/:id/", UserResponder.update)
        router.route(.DELETE, "/users/:id/", UserResponder.destroy)

        router.route(.GET, "/json", JSONResponder.get)
        router.route(.POST, "/json", JSONResponder.post)

        router.route(.GET, "/database", Middleware.authenticate >>> DatabaseResponder.get)

        router.route(.GET, "/redirect", Responder.redirect("http://www.google.com"))

        router.route("/parameters/:id/", ParametersResponder.respond)

        router.route(.GET, "/routes", RoutesResponder.get)

        router.post(Middleware.logResponse)

        super.init(router: router)

        RoutesResponder.paths = router.paths

    }
    
}