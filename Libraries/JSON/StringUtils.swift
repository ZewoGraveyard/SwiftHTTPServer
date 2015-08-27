// StringUtils.swift
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

let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [

    "t": "\t",
    "r": "\r",
    "n": "\n"

]

let escapeMapping: [Character: String] = [

    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",

    "\u{2028}": "\\u2028", // LINE SEPARATOR
    "\u{2029}": "\\u2029", // PARAGRAPH SEPARATOR

    // XXX: countElements("\r\n") is 1 in Swift 1.0
    "\r\n": "\\r\\n"

]

let hexMapping: [UnicodeScalar: UInt32] = [

    "0": 0x0,
    "1": 0x1,
    "2": 0x2,
    "3": 0x3,
    "4": 0x4,
    "5": 0x5,
    "6": 0x6,
    "7": 0x7,
    "8": 0x8,
    "9": 0x9,
    "a": 0xA, "A": 0xA,
    "b": 0xB, "B": 0xB,
    "c": 0xC, "C": 0xC,
    "d": 0xD, "D": 0xD,
    "e": 0xE, "E": 0xE,
    "f": 0xF, "F": 0xF

]

let digitMapping: [UnicodeScalar:Int] = [

    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9
]

public func escapeAsJSONString(source : String) -> String {

    var s = "\""

    for c in source.characters {

        if let escapedSymbol = escapeMapping[c] {

            s.appendContentsOf(escapedSymbol)

        } else {

            s.append(c)

        }

    }

    s.appendContentsOf("\"")
    
    return s

}

func digitToInt(byte: UInt8) -> Int? {

    return digitMapping[UnicodeScalar(byte)]

}

func hexToDigit(byte: UInt8) -> UInt32? {

    return hexMapping[UnicodeScalar(byte)]

}

