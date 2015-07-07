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

    var routes: [HTTPRoute] = []

    struct RouteMatch {

        let pathParameters: [String: String]
        let responder: HTTPRequestResponder
        
    }

}

// MARK: - Public

extension HTTPRouter {

    mutating func addRoute(path: String, responder: HTTPRequestResponder) {

        let route = HTTPRoute(path: path, responder: responder)
        routes.append(route)

    }

    func match(path: String) -> RouteMatch? {

        let matches = routes.filter { route in

            do {

                return try route.regularExpression.matches(path)

            } catch {

                return false
                
            }
            
        }

        if let route = matches.first {

            let responder = route.responder
            let groups = try! route.regularExpression.groups(path)
            let pathParameters = dictionaryFromKeys(route.pathParameterKeys, values: groups)

            return RouteMatch(
                pathParameters: pathParameters,
                responder: responder
            )

        }

        return .None

    }

}
