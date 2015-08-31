// JSONParseError.swift
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

enum JSONParseError: ErrorType, CustomStringConvertible {

    case UnexpectedTokenError(ErrorReason, Parser)
    case InsufficientTokenError(ErrorReason, Parser)
    case ExtraTokenError(ErrorReason, Parser)
    case NonStringKeyError(ErrorReason, Parser)
    case InvalidStringError(ErrorReason, Parser)
    case InvalidNumberError(ErrorReason, Parser)

    // TODO: Check what this actually prints.
    var description: String {

        switch self {

        case UnexpectedTokenError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        case InsufficientTokenError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        case ExtraTokenError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        case NonStringKeyError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        case InvalidStringError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        case InvalidNumberError(let reason, let parser):
            return "\(self)[\(parser.lineNumber):\(parser.columnNumber)]: \(reason)"

        }

    }

}

protocol Parser {

    var lineNumber: Int { get }
    var columnNumber: Int { get }

}
