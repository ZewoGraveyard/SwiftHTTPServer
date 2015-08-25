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

protocol ServerRoute {

    typealias Key: Hashable
    typealias Request
    typealias Response

    var key: Key { get }
    var respondForKey: (key: Key) -> Request throws -> Response { get }

    init(key: Key, respond: Request throws -> Response)
    func matchesKey(key: Key) -> Bool
    
}

class ServerRouter<Route: ServerRoute> {

    var routes: [Route] = []

    var keys: [Route.Key] {

        return routes.map { $0.key }

    }

    func route(key: Route.Key, respond: Route.Request throws -> Route.Response) {

        let route = Route(key: key, respond: respond)
        routes.append(route)

    }

    private var routerRespond: (key: Route.Key) -> (Route.Request throws -> Route.Response)? {

        return { (key: Route.Key) in

            if let route = self.routes.find({$0.matchesKey(key)}) {

                return route.respondForKey(key: key)

            }

            return nil

        }

    }

    func getRespond(key getKey: Route.Request -> () -> Route.Key,
        fallback: (key: Route.Key) -> (Route.Request throws -> Route.Response)) -> (Route.Request throws -> Route.Response) {

            return { (request: Route.Request) in

                let key = getKey(request)()
                let respond = self.routerRespond(key: key) ?? fallback(key: key)
                return try respond(request)
                
            }
            
    }

}