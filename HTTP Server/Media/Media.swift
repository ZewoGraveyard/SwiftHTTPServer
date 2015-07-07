// Media.swift
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

struct Media {

    let path: String
    let data: Data

    init?(path: String) {

        let mediaPath = Media.pathForMedia(path)

        guard let mediaData = Media.getDataForMediaAtPath(mediaPath)
        else { return nil }

        self.path = mediaPath
        self.data = mediaData

    }

    init?(path: String, data: Data) {

        let mediaPath = Media.pathForMedia(path)

        guard let mediaData = Media.saveData(data, forMediaAtPath: mediaPath)
        else { return nil }

        self.path = mediaPath
        self.data = mediaData
        
    }

}

// MARK: - Private

extension Media {

    private static func pathForMedia(path: String) -> String {

        return "Media/" + path

    }

    private static func getDataForMediaAtPath(path: String) -> Data? {
        
        return File(path: path)?.data
        
    }

    private static func saveData(data: Data, forMediaAtPath path: String) -> Data? {

        return File(path: path, data: data)?.data

    }
    
}