// MultipartParserMiddleware.swift
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

    static func parseMultipart(var request: HTTPRequest) throws -> HTTPRequestMiddlewareResult {

        guard let contentType = request.headers["content-type"] else {

            return .Request(request)

        }

        let multipartMediaType = MediaType(contentType)

        if multipartMediaType.type != "multipart/form-data" {

            return .Request(request)

        }

        struct Multipart {

            let contentDisposition: String
            let contentDispositionParameters: [String: String]
            let contentType: String?
            let body: Data
            
        }

        // TODO: Make this throw when shit happens
        func getMultipartFormDataParametersFromBody(body: Data, boundary: String) throws -> [String: String] {

            var parameters: [String: String] = [:]
            var multiparts: [Multipart] = []

            var generator = body.generate()

            func getLine() -> String? {

                let carriageReturn: UInt8 = 13
                let newLine: UInt8 = 10

                var bytes: [UInt8]? = .None

                while let byte = generator.next() where byte != newLine {

                    if bytes == nil {

                        bytes = []

                    }

                    if byte != carriageReturn {

                        bytes!.append(byte)

                    }

                }

                if let bytes = bytes {

                    return String(bytes: bytes)

                }

                return .None

            }

            func getData(var boundary: String) -> Data? {

                boundary = "--\(boundary)"
                let boundaryLastIndex = boundary.utf8.count - 1
                var boundaryIndex = boundaryLastIndex

                var bytes: [UInt8]? = .None

                func getByteForIndex(index: Int) -> UInt8 {

                    return boundary.utf8[boundary.utf8.startIndex.advancedBy(index)]

                }

                func getByteForReversedIndex(index: Int) -> UInt8? {

                    if bytes!.count - index - 1 + boundaryLastIndex < 0 {

                        return .None
                    }

                    return bytes![bytes!.count + index - 1 - boundaryLastIndex]

                }

                var found = false

                while let byte = generator.next() where !found {

                    if bytes == nil {

                        bytes = []

                    }

                    bytes!.append(byte)

                    while let crazyByte = getByteForReversedIndex(boundaryIndex) {

                        if crazyByte == getByteForIndex(boundaryIndex) {

                            boundaryIndex--

                        } else {

                            boundaryIndex = boundaryLastIndex
                            break

                        }

                        if boundaryIndex == 0 {

                            found = true
                            break

                        }

                    }

                }

                if let bytes = bytes {

                    let bytesWithoutBoundary = bytes[0 ..< bytes.count - boundaryLastIndex - 3]
                    return Data(bytes: Array(bytesWithoutBoundary))

                }

                return .None

            }

            while let boundaryLine = getLine() {

                if boundaryLine == "--\(boundary)" {

                    let contentDisposition: String
                    var contentDispositionParameters: [String: String] = [:]
                    var contentType: String? = .None
                    let body: Data

                    if let contentDispositionLine = getLine() {

                        let contentDispositionArray = contentDispositionLine.splitBy(";")
                        let contentDispositionToken = contentDispositionArray[0]
                        contentDisposition = contentDispositionToken.splitBy(":")[1].trim()

                        for index in 1 ..< contentDispositionArray.count {

                            let parameter = contentDispositionArray[index].trim()
                            let parameterArray = parameter.splitBy("=")
                            let parameterKey = parameterArray[0]
                            let parameterValue = parameterArray[1].dropFirstCharacter().dropLastCharacter()
                            contentDispositionParameters[parameterKey] = parameterValue

                        }

                        if let secondLine = getLine() {

                            if secondLine == "" {

                                body = getData(boundary)!

                            } else {

                                let contentTypeLine = secondLine
                                contentType = contentTypeLine.splitBy(":")[1].trim()

                                getLine()
                                body = getData(boundary)!

                            }

                            let multipart = Multipart(
                                contentDisposition: contentDisposition,
                                contentDispositionParameters: contentDispositionParameters,
                                contentType: contentType,
                                body: body
                            )
                            
                            multiparts.append(multipart)
                            
                        }
                        
                    }
                    
                }
                
            }
            
            for multipart in multiparts {
                
                if multipart.contentType == .None {
                    
                    let key = multipart.contentDispositionParameters["name"]!
                    let value = multipart.body
                    parameters[key] = String(data: value)
                    
                } else {
                    
                    let key = multipart.contentDispositionParameters["name"]!
                    let filename = multipart.contentDispositionParameters["filename"]!
                    let value = multipart.body

                    // TODO: put the data in the data dictionary instead of the parameters
                    if let file = File(path: "Media/" + filename, data: value) {
                        
                        parameters[key] = file.path
                        
                    }
                    
                }
                
            }
            
            return parameters
            
        }

        guard let boundary = multipartMediaType.parameters["boundary"] else {

            return .Request(request)

        }

        let parameters = try getMultipartFormDataParametersFromBody(request.body, boundary: boundary)
        request.parameters = request.parameters + parameters

        return .Request(request)

    }
    
}