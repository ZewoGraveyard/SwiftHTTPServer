// HTTPParser.swift
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

struct HTTPParser {

    static func getLine(socket socket: Socket) throws -> String {

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

    static func getHeaders(socket socket: Socket) throws -> [String: String] {

        var headers: [String: String] = [:]

        while true {

            let headerLine = try getLine(socket: socket)

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

    static func getBody(socket socket: Socket, headers: [String: String]) throws -> Data {

        if let contentLenght = headers["content-length"],
            contentSize = Int(contentLenght) where contentSize > 0 {

            return try getBody(socket, size: contentSize)

        }

        if let transferEncoding = headers["transfer-encoding"] where transferEncoding == "chunked" {

            return try getChunkedBody(socket)
                
        }

        return Data()

    }

    private static func getChunkedBody(socket: Socket) throws -> Data {

        var bytes: [UInt8] = []

        while true {

            let chunkSizeString = try getLine(socket: socket)

            let chunkSize = try chunkSizeString.integerFromHexadecimalString()

            if chunkSize == 0 {

                try getLine(socket: socket)
                break

            }

            var counter = 0

            while counter < Int(chunkSize) {

                let byte = try socket.receiveByte()
                bytes.append(byte)
                counter++
                
            }

            try getLine(socket: socket)

        }

        return Data(bytes: bytes)
        
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

}