// URI.swift
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

struct URI {

//    let scheme: String?
//    let userInfo: String?
//    let host: String?
//    let port: String?
    let path: String
    let query: String
//    let query: [String: String?]
//    let fragment: String?

    let absolute: String

    init?(_ string: String) {

        let tokens = string.splitBy("?")

        self.path = tokens[0]

        if tokens.count > 1 {

            self.query = tokens[1]

        } else {

            self.query = ""

        }

        self.absolute = string



//        let uriInfo = get_uri_info(text)
//
//        if uriInfo != nil {
//
//            var query: [String: String?] = [:]
//
//            var queryList = uriInfo.memory.queryList
//
//            while queryList != nil {
//
//                if let key = String.fromCString(queryList.memory.key) {
//
//                    let value = String.fromCString(queryList.memory.value)
//                    query[key] = value
//
//                }
//
//                queryList = queryList.memory.next
//
//            }
//
//            self.scheme = String.fromCString(uriInfo.memory.scheme)
//            self.userInfo = String.fromCString(uriInfo.memory.userInfo)
//            self.host = String.fromCString(uriInfo.memory.host)
//            self.port = String.fromCString(uriInfo.memory.port)
//
//            if let path = String.fromCString(uriInfo.memory.path) {
//
//                self.path = "/" + path
//
//            } else {
//
//                self.path = nil
//
//            }
//
//            self.query = query
//            self.fragment = String.fromCString(uriInfo.memory.fragment)
//            self.absolute = text
//            
//            free_uri_info(uriInfo)
//            
//        } else {
//
//            return nil
//
//        }

    }

}

extension URI: CustomStringConvertible {

    var description: String {

        return absolute

    }

}
