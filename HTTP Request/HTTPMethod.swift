// HTTPMethod.swift
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

enum HTTPMethod {

    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case TRACE
    case OPTIONS
    case CONNECT
    case PATCH

    case Unrecognized(method: String)

    init(string: String) {

        switch string {

        case "GET": self = GET
        case "HEAD": self = HEAD
        case "POST": self = POST
        case "PUT": self = PUT
        case "DELETE": self = DELETE
        case "TRACE": self = TRACE
        case "OPTIONS": self = OPTIONS
        case "CONNECT": self = CONNECT
        case "PATCH": self = PATCH
        default:
            self = Unrecognized(method: string)
            Log.warning("Unrecognized HTTPMethod: \(string)")

        }

    }

}

extension HTTPMethod: Hashable {

    var hashValue: Int {

        return description.hashValue

    }

}

func ==(lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {

    return lhs.hashValue == rhs.hashValue

}

extension HTTPMethod: CustomStringConvertible {
    
    var description: String {
        
        switch self {

        case .GET:                      return "GET"
        case .HEAD:                     return "HEAD"
        case .POST:                     return "POST"
        case .PUT:                      return "PUT"
        case .DELETE:                   return "DELETE"
        case .TRACE:                    return "TRACE"
        case .OPTIONS:                  return "OPTIONS"
        case .CONNECT:                  return "CONNECT"
        case .PATCH:                    return "PATCH"
        case .Unrecognized(let method): return method
            
        }
        
    }
    
}
