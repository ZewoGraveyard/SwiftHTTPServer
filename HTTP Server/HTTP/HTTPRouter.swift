// HTTPRouter.swift
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

    struct HTTPRoute {

        let path: String
        let methods: Set<HTTPMethod>
        let respond: HTTPRequest throws -> HTTPResponse

    }

    private var routes: [String: HTTPMethodRouter] = [:]

    var paths: [String] {

        return routes.keys.array

    }

    let publicFilesBaseDirectory: String

    var respond: (request: HTTPRequest) throws -> HTTPResponse {

        let defaultRespond = Responder.file(baseDirectory: publicFilesBaseDirectory)
        let pathRouter = HTTPPathRouter(defaultRespond: defaultRespond)

        // WARNING: Because of the nature of dictionaries (unordered), if a path matches more than one route. The route that is chosen is undefined. It could be any of them.
        for (path, methodRouter) in routes {

            pathRouter.route(path, respond: methodRouter.respond)

        }

        return pathRouter.respond

    }

    init(publicFilesBaseDirectory: String = "Public/", routes: [HTTPRoute]) {

        self.publicFilesBaseDirectory = publicFilesBaseDirectory

        for route in routes {

            addRoute(route.methods, path: route.path, respond: route.respond)
                
        }

    }

    final class HTTPRouterBuilder {

        var routes: [HTTPRoute] = []

        func all(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.GET, .POST, .PUT, .PATCH, .DELETE],
                respond: respond
            )

            routes.append(route)

        }

        func all(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            all(path, respond())
            
        }

        func get(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.GET],
                respond: respond
            )

            routes.append(route)

        }

        func get(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            get(path, respond())
            
        }

        func post(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.POST],
                respond: respond
            )

            routes.append(route)

        }

        func post(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            post(path, respond())
            
        }

        func put(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.PUT],
                respond: respond
            )

            routes.append(route)

        }

        func put(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            put(path, respond())
            
        }

        func patch(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.PATCH],
                respond: respond
            )

            routes.append(route)

        }

        func patch(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            patch(path, respond())
            
        }

        func delete(path: String, _ respond: HTTPRequest throws -> HTTPResponse) {

            let route = HTTPRoute(
                path: path,
                methods: [.DELETE],
                respond: respond
            )

            routes.append(route)

        }

        func delete(path: String, respond: Void -> HTTPRequest throws -> HTTPResponse) {

            delete(path, respond())
            
        }

        // TODO: Use regex to validate the path string.
        func resources<T: ResourcefulResponder>(path: String, _ responder: T) {

            let indexRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.GET],
                respond: responder.index
            )

            let createRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.POST],
                respond: responder.create
            )

            let showRoute = HTTPRoute(
                path: "/\(path)/:id",
                methods: [.GET],
                respond: responder.show
            )

            let updateRoute = HTTPRoute(
                path: "/\(path)/:id",
                methods: [.PUT, .PATCH],
                respond: responder.update
            )

            let destroyRoute = HTTPRoute(
                path: "/\(path)/:id",
                methods: [.DELETE],
                respond: responder.destroy
            )

            routes += [indexRoute, createRoute, showRoute, updateRoute, destroyRoute]

        }

        // TODO: Use regex to validate the path string.
        func resources<T: ResourcefulResponder>(path: String, responder: Void -> T) {

            resources(path, responder())
            
        }

        // TODO: Use regex to validate the path string.
        func resource<T: ResourcefulResponder>(path: String, _ responder: T) {

            let showRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.GET],
                respond: responder.show
            )
            
            let createRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.POST],
                respond: responder.create
            )
            
            let updateRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.PUT, .PATCH],
                respond: responder.update
            )
            
            let destroyRoute = HTTPRoute(
                path: "/\(path)",
                methods: [.DELETE],
                respond: responder.destroy
            )
            
            routes += [createRoute, showRoute, updateRoute, destroyRoute]
            
        }

        // TODO: Use regex to validate the path string.
        func resource<T: ResourcefulResponder>(path: String, responder: Void -> T) {

            resource(path, responder())

        }

    }

    init(_ build: (router: HTTPRouterBuilder) -> Void) {

        let routerBuilder = HTTPRouterBuilder()
        build(router: routerBuilder)
        self.init(routes: routerBuilder.routes)
        
    }

    private mutating func addRoute(methods: Set<HTTPMethod>, path: String, respond: HTTPRequest throws -> HTTPResponse) {

        func methodNotAllowed(method: HTTPMethod)(request: HTTPRequest) throws -> HTTPResponse {

            return HTTPResponse(status: .MethodNotAllowed)
            
        }

        if routes[path] == nil {

            routes[path] = HTTPMethodRouter(defaultRespond: methodNotAllowed)

        }

        for method in methods {

            routes[path]?.route(method, respond: respond)

        }

    }

}

func >>>(middleware: HTTPRequestMiddleware, router: HTTPRouter) -> HTTPRequest throws -> HTTPResponse {

    return middleware >>> router.respond

}

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

func >>><T: ResourcefulResponder>(middleware: HTTPRequestMiddleware, responder: T) -> SimpleResourcefulResponder {

    return SimpleResourcefulResponder(
        indexFunction:   middleware >>> responder.index,
        createFunction:  middleware >>> responder.create,
        showFunction:    middleware >>> responder.show,
        updateFunction:  middleware >>> responder.update,
        destroyFunction: middleware >>> responder.destroy
    )

}

func >>><T: ResourcefulResponder>(responder: T, middleware: HTTPResponseMiddleware) -> SimpleResourcefulResponder {
    
    return SimpleResourcefulResponder(
        indexFunction:   responder.index   >>> middleware,
        createFunction:  responder.create  >>> middleware,
        showFunction:    responder.show    >>> middleware,
        updateFunction:  responder.update  >>> middleware,
        destroyFunction: responder.destroy >>> middleware
    )
    
}
