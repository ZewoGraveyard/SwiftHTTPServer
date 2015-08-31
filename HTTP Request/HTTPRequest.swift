// HTTPRequest.swift
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

struct HTTPRequest: Parameterizable, KeepAliveType {

    let method: HTTPMethod
    let uri: URI
    let version: String
    var headers: [String: String]
    let body: Data
    var parameters: [String: String]
    var data: [String: Any]

    init(method: HTTPMethod,
        uri: URI,
        version: String = "HTTP/1.1",
        headers: [String: String] = [:],
        body: Data = Data(),
        parameters: [String: String] = [:],
        data: [String: Any] = [:]) {

        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.parameters = parameters
        self.data = data

    }

    func getData<T>(key: String) throws -> T {

        guard let data = self.data[key] as? T else {

            throw HTTPError.BadRequest(
                description: "Could not get data from key: \(key). Data doesn't exist or it's not a value of the specified type."
            )

        }

        return data

    }

    func getParameter(parameter: String) throws -> String {

        guard let value = parameters[parameter] else {

            throw HTTPError.BadRequest(
                description: "Missing field: \(parameter)."
            )
            
        }

        return value
        
    }

    func pathRouterKey() -> String {

        return uri.path
        
    }

    func methodRouterKey() -> HTTPMethod {

        return method

    }

    var keepAlive: Bool {

        set {

            if (newValue) { headers["connection"] = "keep-alive" }

        }

        get {

            return (headers["connection"]?.trim().lowercaseString == "keep-alive") ?? false
            
        }
        
    }
    
}

extension HTTPRequest: CustomStringConvertible {

    var description: String {

        var string = "\(method) \(uri) HTTP/1.1\n"

        for (index, (header, value)) in headers.enumerate() {

            string += "  \(header): \(value)"

            if index != headers.count - 1 {

                string += "\n"

            }

        }

        string += "\n\(body)"

        return string

    }

}

extension HTTPRequest: CustomColorLogStringConvertible {

    var logDescription: String {

        var string = Log.lightGreen

        string += "\(method) \(uri) HTTP/1.1\n"
        string += Log.darkGreen

        for (index, (header, value)) in headers.enumerate() {

            string += "  \(header): \(value)"

            if index != headers.count - 1 {

                string += "\n"

            }

        }

        string += Log.green
        string += "\n\(body)"
        string += Log.reset
        
        return string
        
    }
    
}