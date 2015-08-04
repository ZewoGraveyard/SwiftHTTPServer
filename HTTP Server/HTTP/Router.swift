// Router.swift
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

final class PathRouter: ServerRouter<PathRoute> {

    let defaultRespond: (path: String) -> HTTPRequest throws -> HTTPResponse

    init(defaultRespond: (path: String) -> HTTPRequest throws -> HTTPResponse) {

        self.defaultRespond = defaultRespond

    }

    var respond: HTTPRequest throws -> HTTPResponse {

        return getRespond(
            key: HTTPRequest.pathRouterKey,
            defaultRespond: defaultRespond
        )
        
    }

}

struct PathRoute: ServerRoute {

    let key: String
    let respond: HTTPRequest throws -> HTTPResponse

    private let parameterKeys: [String]
    private let regularExpression: RegularExpression

    init(key: String, respond: HTTPRequest throws -> HTTPResponse) {

        let parameterRegularExpression = try! RegularExpression(pattern: ":([[:alnum:]]+)")
        let pattern = try! parameterRegularExpression.replace(key, withTemplate: "([[:alnum:]]+)")

        self.key = key
        self.parameterKeys = try! parameterRegularExpression.groups(key)
        self.regularExpression = try! RegularExpression(pattern: "^" + pattern + "$")
        self.respond = respond

    }

    func matchesKey(key: String) -> Bool {

        return try! regularExpression.matches(key)

    }

    func parametersForKey(key: String) -> [String: String] {

        let values = try! regularExpression.groups(key)
        return dictionaryFromKeys(parameterKeys, values: values)
        
    }
    
}

final class MethodRouter: ServerRouter<MethodRoute> {

    let defaultRespond: (method: HTTPMethod) -> HTTPRequest throws -> HTTPResponse

    init(defaultRespond: (method: HTTPMethod) -> HTTPRequest throws -> HTTPResponse) {

        self.defaultRespond = defaultRespond
        
    }

    var respond: HTTPRequest throws -> HTTPResponse {

        return getRespond(
            key: HTTPRequest.methodRouterKey,
            defaultRespond: defaultRespond
        )
        
    }

}

struct MethodRoute: ServerRoute {

    let key: HTTPMethod
    let respond: HTTPRequest throws -> HTTPResponse


    init(key: HTTPMethod, respond: HTTPRequest throws -> HTTPResponse) {

        self.key = key
        self.respond = respond

    }

    func matchesKey(key: HTTPMethod) -> Bool {

        return self.key == key

    }

    func parametersForKey(key: HTTPMethod) -> [String: String] {

        return [:]

    }

}

struct Router: ArrayLiteralConvertible {

    struct Route {

        let path: String
        let methods: Set<HTTPMethod>
        let respond: HTTPRequest throws -> HTTPResponse

    }

    private var routes: [String: MethodRouter] = [:]

    var paths: [String] {

        return routes.keys.array

    }

    let publicFilesBaseDirectory: String

    var respond: (request: HTTPRequest) throws -> HTTPResponse {

        let defaultRespond = Responder.file(baseDirectory: publicFilesBaseDirectory)
        let pathRouter = PathRouter(defaultRespond: defaultRespond)

        // WARNING: Because of the nature of dictionaries (unordered), if a path matches more than one route. The route that is chosen is undefined. It could be any of them.
        for (path, methodRouter) in routes {

            pathRouter.route(path, respond: methodRouter.respond)

        }

        return pathRouter.respond

    }

    init(publicFilesBaseDirectory: String = "Public/", routes: [[Route]]) {

        self.publicFilesBaseDirectory = publicFilesBaseDirectory

        for routeSet in routes {

            for route in routeSet {

                addRoute(route.methods, path: route.path, respond: route.respond)
                
            }
            
        }

    }

    init(arrayLiteral routes: [Route]...) {

        self.init(routes: routes)
        
    }

    private mutating func addRoute(methods: Set<HTTPMethod>, path: String, respond: HTTPRequest throws -> HTTPResponse) {

        func methodNotAllowed(method: HTTPMethod)(request: HTTPRequest) throws -> HTTPResponse {

            return HTTPResponse(status: .MethodNotAllowed)
            
        }

        if routes[path] == nil {

            routes[path] = MethodRouter(defaultRespond: methodNotAllowed)

        }

        for method in methods {

            routes[path]?.route(method, respond: respond)

        }

    }

    static func all(path: String, _ respond: HTTPRequest throws -> HTTPResponse)  -> [Route] {

        let route = Route(
            path: path,
            methods: [.GET, .POST, .PUT, .PATCH, .DELETE],
            respond: respond
        )

        return [route]

    }

    static func get(path: String, _ respond: HTTPRequest throws -> HTTPResponse) -> [Route] {

        let route = Route(
            path: path,
            methods: [.GET],
            respond: respond
        )

        return [route]

    }

    static func post(path: String, _ respond: HTTPRequest throws -> HTTPResponse) -> [Route] {

        let route = Route(
            path: path,
            methods: [.POST],
            respond: respond
        )

        return [route]

    }

    static func put(path: String, _ respond: HTTPRequest throws -> HTTPResponse) -> [Route] {

        let route = Route(
            path: path,
            methods: [.PUT],
            respond: respond
        )

        return [route]

    }

    static func patch(path: String, _ respond: HTTPRequest throws -> HTTPResponse) -> [Route] {

        let route = Route(
            path: path,
            methods: [.PATCH],
            respond: respond
        )

        return [route]

    }

    static func delete(path: String, _ respond: HTTPRequest throws -> HTTPResponse) -> [Route] {

        let route = Route(
            path: path,
            methods: [.DELETE],
            respond: respond
        )

        return [route]

    }

    // TODO: Use regex to validate the path string.
    static func resources<T: ResourcefulResponder>(path: String, _ responder: T) -> [Route] {

        let indexRoute = Route(
            path: "/\(path)/",
            methods: [.GET],
            respond: responder.index
        )

        let createRoute = Route(
            path: "/\(path)/",
            methods: [.POST],
            respond: responder.create
        )

        let showRoute = Route(
            path: "/\(path)/:id/",
            methods: [.GET],
            respond: responder.show
        )

        let updateRoute = Route(
            path: "/\(path)/:id/",
            methods: [.PUT, .PATCH],
            respond: responder.update
        )

        let destroyRoute = Route(
            path: "/\(path)/:id/",
            methods: [.DELETE],
            respond: responder.destroy
        )

        return [indexRoute, createRoute, showRoute, updateRoute, destroyRoute]

    }

    // TODO: Use regex to validate the path string.
    static func resource<T: ResourcefulResponder>(path: String, _ responder: T) -> [Route] {

        let showRoute = Route(
            path: "/\(path)/",
            methods: [.GET],
            respond: responder.show
        )

        let createRoute = Route(
            path: "/\(path)/",
            methods: [.POST],
            respond: responder.create
        )

        let updateRoute = Route(
            path: "/\(path)/",
            methods: [.PUT, .PATCH],
            respond: responder.update
        )
        
        let destroyRoute = Route(
            path: "/\(path)/",
            methods: [.DELETE],
            respond: responder.destroy
        )
        
        return [createRoute, showRoute, updateRoute, destroyRoute]
        
    }

}

func >>>(middleware: HTTPRequestMiddleware, router: Router) -> HTTPRequest throws -> HTTPResponse {

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
