// UserResponder.swift
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

struct User {

    let name: String

}

struct Collection<T> {

    var elements: [String: T] = [:]
    private var currentId = 0

    private mutating func getNewId() -> String {

        let id = "\(currentId)"
        currentId++
        return id

    }

    mutating func add(element element: T) {

        let id = getNewId()
        elements[id] = element

    }

    func get(id id: String) -> T? {

        return elements[id]

    }

    mutating func update(id id: String, element: T) {

        elements[id] = element

    }

    mutating func delete(id id: String) {
        
        elements.removeValueForKey(id)
        
    }

}

final class UserResponder : ResourcefulResponder {

    var users = Collection<User>()

    func index(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(text: "\(users.elements)")

    }

    func create(request: HTTPRequest) throws -> HTTPResponse {

        let name = try request.getParameter("name")
        let user = User(name: name)
        users.add(element: user)

        return HTTPResponse(status: .Created)

    }

    func show(request: HTTPRequest) throws -> HTTPResponse {

        let id = try request.getParameter("id")
        let user = users.get(id: id)

        return HTTPResponse(text: "\(user)")
        
    }

    func update(request: HTTPRequest) throws -> HTTPResponse {

        let id = try request.getParameter("id")
        let name = try request.getParameter("name")
        let user = User(name: name)
        users.update(id: id, element: user)

        return HTTPResponse(status: .NoContent)

    }

    func destroy(request: HTTPRequest) throws -> HTTPResponse {

        let id = try request.getParameter("id")
        users.delete(id: id)
        
        return HTTPResponse(status: .NoContent)

    }

}