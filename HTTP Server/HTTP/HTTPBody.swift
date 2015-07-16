// HTTPBody.swift
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

protocol HTTPBody {

    var contentType: InternetMediaType? { get }
    var data: Data? { get }

}

struct HTTPBodyFactory {

    static func bodyFromData(data: Data?, headers: [String: String]) throws -> HTTPBody {

        guard let data = data
            else { return EmptyBody() }

        guard let contentType = headers["content-type"]
            else { return DataBody(data: data) }

        let mediaType = InternetMediaType(string: contentType)

        switch mediaType {

        case .ApplicationJSON:
            return try JSONBody(data: data)

        case .ApplicationXWWWFormURLEncoded:
            return try FormURLEncodedBody(data: data)

        case .MultipartFormData(let boundary):
            return MultipartFormDataBody(data: data, boundary: boundary)

        case .TextPlain:
            return try TextBody(data: data)

        case (let contentType):
            return DataBody(data: data, contentType: contentType)
            
        }
        
    }

}