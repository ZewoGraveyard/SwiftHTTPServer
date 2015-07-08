// Asset.swift
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

#if os(iOS)
 
import Foundation
    
#endif

struct Asset {

    let path: String
    let data: Data

    init?(path: String) {

        let assetPath = Asset.pathForAsset(path)

        guard let assetData = Asset.getDataForAssetAtPath(assetPath)
        else { return nil }

        self.path = assetPath
        self.data = assetData

    }

}

// MARK: - Private

extension Asset {

    private static func pathForAsset(path: String) -> String {

        return "Assets/" + path

    }

    private static func getDataForAssetAtPath(path: String) -> Data? {
        
        // TODO: Find out if it's possible to access files in iOS with fopen
        #if os(iOS)
            
            let resourcePath = NSBundle.mainBundle().resourcePath!
            let filePath = resourcePath.stringByExpandingTildeInPath.stringByAppendingPathComponent(path)
            
            if let data = NSData(contentsOfFile: filePath) {

                let count = data.length / sizeof(UInt8)
                var array = [UInt8](count: count, repeatedValue: 0)
                data.getBytes(&array, length:count * sizeof(UInt8))
                return Data(bytes: array)
                
            }
            
            return nil
            
        #elseif os(OSX)
            
            return File(path: path)?.data
            
        #endif
        
    }

}