// HeaderMiddleware.swift
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

protocol HeaderType {

    var headers: [String: String] { get set }
    
}

extension Middleware {

    static func addHeaders<Request, Response>(headers: [String: String]) -> Request -> RequestMiddlewareResult<Request, Response> {

        return { request in

            if var request = request as? HeaderType {

                request.headers = request.headers + headers
                return .Request(request as! Request)

            } else {

                return .Request(request)
                
            }
            
        }
        
    }

    static func addHeaders<Response>(headers: [String: String]) -> (Response -> Response) {

        return { response in

            if var response = response as? HeaderType {

                response.headers = response.headers + headers
                return response as! Response

            } else {

                return response
                
            }
            
        }
        
    }
    
}
