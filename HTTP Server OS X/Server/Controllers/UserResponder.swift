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

struct UserResponder {

    static var users: [String: String] = [:]
    static var usersId = 0

    static func index(request: HTTPRequest) throws -> HTTPResponse {

        return HTTPResponse(status: .OK, body: TextBody(text: "\(users)"))

    }

    static func create(request: HTTPRequest) throws -> HTTPResponse {

        guard let body = request.body as? FormURLEncodedBody,
                  user = body.parameters["user"]
        else { return HTTPResponse(status: .BadRequest) }

        users["\(usersId)"] = user
        usersId++

        return HTTPResponse(status: .OK)

    }

    static func show(request: HTTPRequest) throws -> HTTPResponse {

        guard let id = request.parameters["id"],
                user = users[id]
        else { return HTTPResponse(status: .NotFound) }

        return HTTPResponse(status: .OK, body: TextBody(text: "\(user)"))
        
    }

    static func update(request: HTTPRequest) throws -> HTTPResponse {

        guard let id = request.parameters["id"],
                body = request.body as? FormURLEncodedBody,
                user = body.parameters["user"]
        where users[id] != nil
        else { return HTTPResponse(status: .BadRequest) }

        users[id] = user

        return HTTPResponse(status: .OK, body: TextBody(text: "\(user)"))

    }

    static func destroy(request: HTTPRequest) throws -> HTTPResponse {

        guard let id = request.parameters["id"]
        else { return HTTPResponse(status: .BadRequest) }

        users.removeValueForKey(id)

        return HTTPResponse(status: .OK)


    }

}