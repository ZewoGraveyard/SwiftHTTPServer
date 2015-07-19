// File.swift
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

struct File {

    let data: Data

    init?(path: String) {

        guard let data = File.getData(path)
        else { return nil }

        self.data = data

    }

    init?(path: String, data: Data) {

        guard let data = File.saveData(data, atPath: path)
        else { return nil }

        self.data = data

    }

    private static func saveData(data: Data, atPath path: String) -> Data? {

        let file = fopen(path, "w")

        if file == .None {

            return .None
            
        }

        fwrite(data.bytes, 1, data.length, file)
        fclose(file)

        return data

    }

    private static func getData(path: String) -> Data? {

        let file = fopen(path, "r")

        if file == nil {

            return .None

        }

        var array: [UInt8] = []

        while true {

            let element = fgetc(file)

            if element == -1 {

                break

            }

            if feof(file) != 0 {

                break

            }

            array.append(UInt8(element))

        }

        fclose(file)

        return Data(bytes: array)

    }
    
}
