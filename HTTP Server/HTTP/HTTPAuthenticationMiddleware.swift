// HTTPAuthenticationMiddleware.swift
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

    static func authenticate(request: HTTPRequest) -> HTTPRequestMiddlewareResult {

        if let authorization = request.headers["authorization"] where authorization == "password" {

            return .Request(request)

        } else {

            let response = HTTPResponse(status: .Unauthorized, body: TextBody(text: "Unauthorized"))
            return .Response(response)

        }

    }

}

extension Middleware {

    static func parseJSONBody(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        guard let data = request.body.data,
           contentType = request.headers["content-type"] where
        InternetMediaType(string: contentType) == .ApplicationJSON else {

            return .Request(request)
            
        }

        let newRequest = HTTPRequest(
            method: request.method,
            URI: request.URI,
            version: request.version,
            headers: request.headers,
            body: try JSONBody(data: data),
            parameters: request.parameters
        )

        return .Request(newRequest)

    }
    
}

extension Middleware {

    static func parseFormURLEncodedBody(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        guard let data = request.body.data,
            contentType = request.headers["content-type"] where
            InternetMediaType(string: contentType) == .ApplicationXWWWFormURLEncoded else {

                return .Request(request)

        }

        let newRequest = HTTPRequest(
            method: request.method,
            URI: request.URI,
            version: request.version,
            headers: request.headers,
            body: try FormURLEncodedBody(data: data),
            parameters: request.parameters
        )

        return .Request(newRequest)
        
    }
    
}

extension Middleware {

    static func parseMultipartBody(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        guard let data = request.body.data,
            contentType = request.headers["content-type"] else {

                return .Request(request)

        }

        // TODO: Look for the if case stuff
        switch InternetMediaType(string: contentType) {

        case .MultipartFormData(let boundary):

            let newRequest = HTTPRequest(
                method: request.method,
                URI: request.URI,
                version: request.version,
                headers: request.headers,
                body: try MultipartFormDataBody(data: data, boundary: boundary),
                parameters: request.parameters
            )

            return .Request(newRequest)

        default:
            return .Request(request)

        }
        
    }
    
}

extension Middleware {

    static func parseTextBody(request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        guard let data = request.body.data,
            contentType = request.headers["content-type"] where
            InternetMediaType(string: contentType) == .TextPlain else {

                return .Request(request)

        }

        let newRequest = HTTPRequest(
            method: request.method,
            URI: request.URI,
            version: request.version,
            headers: request.headers,
            body: try TextBody(data: data),
            parameters: request.parameters
        )

        return .Request(newRequest)
        
    }
    
}
