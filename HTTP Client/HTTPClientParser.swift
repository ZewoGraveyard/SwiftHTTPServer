// HTTPClientParser.swift
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

struct HTTPClientParser {
    
    static func receiveHTTPResponse(socket: Socket) throws -> HTTPResponse {
        
        let status = try getStatus(socket)
        let headers = try getHeaders(socket)
        let body = try getBody(socket, headers: headers)
        
        return HTTPResponse(
            status: status,
            headers: headers,
            body: body != nil ? DataBody(data: body!) : EmptyBody()
        )
        
    }
    
}

// MARK: - Private

extension HTTPClientParser {
    
    private static func getStatus(socket: Socket) throws -> HTTPStatus {
        
        let statusLine = try getLine(socket)
        let statusLineTokens = statusLine.splitBy(" ")
        
        if statusLineTokens.count != 3 {
            
            throw Error.Generic("Impossible to create HTTP Request", "Invalid request line")
            
        }
        
        guard let statusCode = Int(statusLineTokens[1])
        else { throw Error.Generic("Impossible to create HTTP Request", "Invalid status code") }
        
        let reasonPhrase = statusLineTokens[2]
        
        return HTTPStatus(statusCode: statusCode, reasonPhrase: reasonPhrase)
    }
    
    private static func getHeaders(socket: Socket) throws -> [String: String] {
        
        var headers: [String: String] = [:]
        
        while true {
            
            let headerLine = try getLine(socket)
            
            if headerLine.isEmpty {
                
                return headers
                
            }
            
            let headerTokens = headerLine.splitBy(":")
            
            if headerTokens.count >= 2 {
                
                let key = headerTokens[0].lowercaseString
                let value = headerTokens[1].trim()
                
                if !key.isEmpty && !value.isEmpty {
                    
                    headers[key] = value
                    
                }
                
            }
            
        }
        
    }
    
    private static func getBody(socket: Socket, headers: [String: String]) throws -> Data? {
        
        if let contentLenght = headers["content-length"], contentSize = Int(contentLenght) where contentSize > 0 {
            
            return try getBody(socket, size: contentSize)
            
        }
        
        return .None
        
    }
    
    private static func getBody(socket: Socket, size: Int) throws -> Data {
        
        var bytes: [UInt8] = []
        var counter = 0
        
        while counter < size {
            
            let byte = try socket.receiveByte()
            bytes.append(byte)
            counter++
            
        }
        
        return Data(bytes: bytes)
        
    }
    
    private static func getLine(socket: Socket) throws -> String {
        
        let CR: UInt8 = 13
        let NL: UInt8 = 10
        
        var characters: String = ""
        var byte: UInt8 = 0
        
        repeat {
            
            byte = try socket.receiveByte()
            
            if byte > CR {
                
                characters.append(Character(UnicodeScalar(byte)))
                
            }
            
        } while byte != NL
        
        return characters
        
    }
    
}