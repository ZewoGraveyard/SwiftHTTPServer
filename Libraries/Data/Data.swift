// Data.swift
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

public struct Data {

    let bytes: [UInt8]

    var length: Int {

        return bytes.count

    }

    init(bytes: [UInt8]) {

        self.bytes = bytes

    }

    init(string: String) {

        var chars: [UInt8] = []

        for char in string.utf8 {

            chars.append(char)

        }

        self.bytes = chars
        
    }

    var empty: Bool {

        return bytes.count == 0
        
    }

}


extension Data: CustomStringConvertible {

    public var description: String {

        if length > 500 {

            return "Data: Data too large to be represented as string."

        }

        if let string = String(data: self) {

            return string

        } else {

            return "Data: Unable to convert data to UTF-8 string."

        }

    }

}

extension Data: SequenceType {

    public func generate() -> IndexingGenerator<[UInt8]> {

        return IndexingGenerator(bytes)

    }

}
