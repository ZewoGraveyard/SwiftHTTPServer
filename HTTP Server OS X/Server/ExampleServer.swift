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

final class ExampleServer: HTTPServer {

    init() {

        func authorize(username: String, password: String) throws -> User {

            switch (username, password) {

            case ("username", "password"): return User(name: "Name")
            default: throw Error.Generic("Unable to authenticate user", "Wrong credentials")

            }

        }

        let respond = Middleware.logRequest >>> Middleware.parseFormURL >>> [

            Router.get("/login", LoginResponder.show),
            Router.post("/login", LoginResponder.authenticate),
            Router.resources("users", UserResponder()),
            Router.get("/json", JSONResponder.get),
            Router.post("/json", Middleware.parseJSON >>> JSONResponder.post),
            Router.get("/database", DatabaseResponder.get),
            Router.get("/redirect", Responder.redirect("http://www.google.com")),
            Router.all("/parameters/:id/", Middleware.basicAuthentication(authorize) >>> ParametersResponder.respond)

        ] >>> Middleware.logResponse

        super.init(respond: respond)

    }
    
}