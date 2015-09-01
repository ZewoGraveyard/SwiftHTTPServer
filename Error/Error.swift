// Error.swift
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

typealias ErrorDescription = String
typealias ErrorReason = String

var lastPOSIXErrorDescription: String? {

    return POSIXErrorDescription(errno)

}

func POSIXErrorDescription(errorNumber: Int32) -> String? {

    return  String.fromCString(UnsafePointer(strerror(errorNumber)))

}

enum Error: ErrorType {

    case Generic(ErrorDescription, ErrorReason)

    static func lastSystemError(reason reason: String) -> Error {

        if let errorDescription = lastPOSIXErrorDescription {

            return Error.Generic(errorDescription, reason)

        }

        return Error.Generic("Unknown Error", reason)

    }

    static func defaultFailureHandler(error: ErrorType) {

        Log.error("Error: \(error)")
        
    }

}