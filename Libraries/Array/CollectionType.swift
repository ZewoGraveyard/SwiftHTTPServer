// Array.swift
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

extension CollectionType {

    /// Returns the first value of `self`
    /// that satisfy the predicate `isMatch`.
    func find(@noescape isMatch: (Self.Generator.Element) -> Bool) -> Self.Generator.Element? {

        for element in self {

            if isMatch(element) {

                return element

            }

        }
        
        return .None
        
    }

    /// Returns the first value of index
    /// that satisfy the predicate `isMatch`.
    func findIndex(@noescape isMatch: (Self.Generator.Element) -> Bool) -> Int? {

        for (index, element) in self.enumerate() {

            if isMatch(element) {

                return index

            }

        }
        
        return .None
        
    }
    
}