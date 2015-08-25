// HTTPError.swift
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

enum HTTPError : ErrorType {

    case BadRequest(description: String)
    case Unauthorized(description: String)
    case NotFound(description: String)

    static func respondError(error: ErrorType) -> HTTPResponse {

        let response: HTTPResponse

        switch error {

        case HTTPError.BadRequest(let description):
            response = HTTPResponse(status: .BadRequest, text: "\(description)")

        case HTTPError.Unauthorized(let description):
            response = HTTPResponse(status: .Unauthorized, text: "\(description)")

        case HTTPError.NotFound(let description):
            response = HTTPResponse(status: .NotFound, text: "\(description)")

        default:
            response = HTTPResponse(status: .InternalServerError, text: "\(error)")
            
        }

        Log.error(error)
        Log.info(response)
        return response
        
    }

}

extension HTTPError : CustomStringConvertible {

    var description: String {

        switch self {

        case .BadRequest(let description):
            return description

        case .Unauthorized(let description):
            return description

        case .NotFound(let description):
            return description

        }

    }

}