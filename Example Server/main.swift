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

struct ExampleServer {

    static let respond = Middleware.logRequest >>> Middleware.parseURLEncoded >>> HTTPRouter(basePath: "/api") { router in

        router.group("/v1") { group in

            group.get("/ok") { _ in HTTPResponse() }

        }

        router.get("/login", LoginResponder.show)
        router.post("/login", LoginResponder.authenticate)

        router.resources("/users") {

            Middleware.basicAuthentication(Authenticator.authenticate) >>> UserResponder()

        }

        router.get("/json", JSONResponder.get)
        router.post("/json", Middleware.parseJSON >>> JSONResponder.post)
        router.get("/redirect", Responder.redirect("http://www.google.com"))
        router.any("/parameters/:id/", ParametersResponder.respond)

        router.fallback = Responder.file(baseDirectory: "public")

    } >>> HTTPError.respondError >>> Middleware.log

}

func >>><Request, Response>(respond: (Request -> Response), f: ((Request, Response) -> Void)) -> (Request -> Response) {
    
    return { request in
     
        let response = respond(request)
        
        f(request, response)
        
        return response
        
    }
    
}

UVHTTPServer(respond: ExampleServer.respond).start(port: 9090)