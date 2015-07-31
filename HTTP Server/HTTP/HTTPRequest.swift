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

struct HTTPRequest: ParameterizableRequest, KeepConnectionRequest {

    let method: HTTPMethod
    let URI: String
    let version: HTTPVersion
    let headers: [String: String]
    let body: Data
    let parameters: [String: String]
    let data: [String: Any]

    init(method: HTTPMethod,
        URI: String,
        version: HTTPVersion = .HTTP_1_1,
        headers: [String: String] = [:],
        body: Data = Data(),
        parameters: [String: String] = [:],
        data: [String: Any] = [:]) {

        self.method = method
        self.URI = URI
        self.version = version
        self.headers = headers
        self.body = body
        self.parameters = parameters
        self.data = data

    }

    func copyWithData(data: [String: Any]) -> HTTPRequest {

        return HTTPRequest(
            method: self.method,
            URI: self.URI,
            version: self.version,
            headers: self.headers,
            body: self.body,
            parameters: self.parameters,
            data: self.data + data
        )

    }

    func getData<T>(key: String) throws -> T {

        guard let data = self.data[key] as? T else {

            throw Error.Generic("Could not get data from key: \(key)", "Data doesn't exist or it's not of the specified type")
            
        }

        return data

    }

    func getPath() -> String {

        return path
        
    }

    func getMethod() -> HTTPMethod {

        return method

    }

    var contentType: InternetMediaType? {

        guard let contentType = headers["content-type"] else {

            return nil

        }

        return InternetMediaType(string: contentType)
        
    }

}

extension HTTPRequest {

    func getParameter(parameter: String) throws -> String {

        if let parameter = parameters[parameter] {

            return parameter

        } else {

            throw Error.Generic("Could not get parameter \(parameter)", "Parameter is not in the parameters dictionary")
            
        }
        
    }
    
}

extension HTTPRequest {

    var path: String {

        return URI.splitBy("?").first!

    }

}

extension HTTPRequest {

    func copyWithParameters(parameters: [String: String]) -> HTTPRequest {

        return HTTPRequest(
            method:     self.method,
            URI:        self.URI,
            version:    self.version,
            headers:    self.headers,
            body:       self.body,
            parameters: self.parameters + parameters
        )

    }

}

extension HTTPRequest {

    var queryParameters: [String: String] {

        if let query = URI.splitBy("?").last {

            return query.queryParameters

        }

        return [:]

    }

}

extension HTTPRequest {

    var keepConnection: Bool {

        if let value = headers["connection"] {

            return "keep-alive" == value.trim().lowercaseString
            
        }
        
        return false
        
    }
    
}

extension HTTPRequest: CustomStringConvertible {

    var description: String {

        var string = "\(method) \(URI) HTTP/1.1\n"

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

        string += "\(method) \(URI) HTTP/1.1\n"
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