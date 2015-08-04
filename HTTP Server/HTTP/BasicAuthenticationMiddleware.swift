// BasicAuthenticationMiddleware.swift
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

extension Middleware {

    static func basicAuthentication(authenticate: (username: String, password: String) throws -> [String: Any])(var request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        if let authorization = request.headers["authorization"] {

            let authorizationTokens = authorization.splitBy(" ")

            if authorizationTokens.count == 2 && authorizationTokens[0] == "Basic" {

                let encodedCredentials = authorizationTokens[1]
                let decodedCredentials = base64Decode(encodedCredentials)

                let decodedCredentialsTokens = decodedCredentials.splitBy(":")

                if decodedCredentialsTokens.count == 2 {

                    let username = decodedCredentialsTokens[0]
                    let password = decodedCredentialsTokens[1]

                    let data = try authenticate(username: username, password: password)

                    request.data = request.data + data
                    return .Request(request)

                }
                
            }

        }

        let response = HTTPResponse(status: .Unauthorized, text: "Unauthorized")
        return .Response(response)

    }

}
