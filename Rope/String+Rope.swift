// String+Rope.swift
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

extension String {

    init?(data: Data) {

        self.init(bytes: data.bytes)

    }

    init?(bytes: [Int8]) {

        var buffer: [UInt8] = [UInt8](count: bytes.count, repeatedValue: 0)
        memcpy(&buffer, bytes, bytes.count)
        self.init(bytes: buffer)

    }

    init?(bytes: [UInt8]) {

        var encodedString = ""
        var decoder = UTF8()
        var generator = bytes.generate()
        var finished: Bool = false

        while !finished {

            let decodingResult = decoder.decode(&generator)

            switch decodingResult {

            case .Result(let char):
                encodedString.append(char)

            case .EmptyInput:
                finished = true

            case .Error:
                return nil

            }

        }

        self.init(encodedString)

    }

    var bytes: [UInt8] {

        return [] + utf8

    }

    var URLDecoded: String? {


            let space: UInt8 = 32
            let percent: UInt8 = 37
            let plus: UInt8 = 43

            var encodedArray: [UInt8] = bytes
            var decodedArray: [UInt8] = []

            for var index = 0; index < encodedArray.count; {

                let codeUnit = encodedArray[index]

                if codeUnit == percent {

                    let unicodeA = UnicodeScalar(encodedArray[index + 1])
                    let unicodeB = UnicodeScalar(encodedArray[index + 2])

                    let hexadecimalString = "\(unicodeA)\(unicodeB)"
                    
                    guard let character = hexadecimalString.integerFromHexadecimalString() else {

                        return nil

                    }

                    decodedArray.append(UInt8(character))

                    index += 3

                } else if codeUnit == plus {

                    decodedArray.append(space)
                    index++

                } else {

                    decodedArray.append(codeUnit)
                    index++

                }

            }

            return String(bytes: decodedArray)



    }

    var queryParameters: [String: String] {

        var parameters: [String: String] = [:]

        for parameter in self.splitBy("&") {

            let tokens = parameter.splitBy("=")

            if tokens.count >= 2 {

                let key = tokens[0].URLDecoded
                let value = tokens[1].URLDecoded

                if let key = key, value = value {

                    parameters[key] = value
                    
                }
                
            }
            
        }
        
        return parameters
        
    }

    func dropFirstCharacter() -> String {

        if self.characters.count == 1 || self.characters.count == 0 {

            return ""

        }

        return String(self.characters.dropFirst())

    }

    func dropLastCharacter() -> String {

        if self.characters.count == 1 || self.characters.count == 0 {

            return ""
            
        }

        return String(self.characters.dropLast())
        
    }

    func rangesOfString(string: String) -> [Range<String.Index>] {

        var ranges = [Range<String.Index>]()
        var startIndex = self.startIndex

        // check first that the first character of search string exists
        if self.characters.contains(string.characters.first!) {

            // if so set this as the place to start searching
            startIndex = self.characters.indexOf(string.characters.first!)!

        } else {

            // if not return empty array
            return ranges

        }

        var i = self.startIndex.distanceTo(startIndex)

        while i <= self.characters.count - string.characters.count {

            if self[self.startIndex.advancedBy(i) ..< self.startIndex.advancedBy(i+string.characters.count)] == string {

                ranges.append(
                    Range(
                        start: self.startIndex.advancedBy(i),
                        end: self.startIndex.advancedBy(i+string.characters.count)
                    )
                )
                
                i = i + string.characters.count

            } else {

                i++

            }

        }

        return ranges

    }

    func splitByString(separator: String, allowEmptySlices: Bool = false) -> [String] {

        if separator.isEmpty {

            return [self]

        }

        var parts: [String] = []

        let ranges = rangesOfString(separator)

        if ranges.count == 0 {

            return [self]

        }

        for (index, range) in ranges.enumerate() {

            if index == 0 {

                let firstPart = self[startIndex ..< range.startIndex]
                parts.append(firstPart)

            }

            if index > 0 {

                let lastRange = ranges[index - 1]
                let part = self[lastRange.endIndex ..< range.startIndex]
                parts.append(part)
                
            }

            if index == ranges.count - 1 {

                let lastPart = self[range.endIndex ..< endIndex]
                parts.append(lastPart)

            }
            
        }

        if !allowEmptySlices {

            parts = parts.filter { $0 != "" }

        }

        return parts

    }

//    func splitBySeparatorsInString(separators: String, allowEmptySlices: Bool = false) -> [String] {
//
//        return split(characters, allowEmptySlices: allowEmptySlices) { separators.characters.contains($0) }.map { String($0) }
//
//    }

    func splitBy(separator: Character, allowEmptySlices: Bool = false) -> [String] {

        return characters.split(allowEmptySlices: allowEmptySlices) { $0 == separator }.map { String($0) }

    }

    func trim() -> String {

        return stringByTrimmingCharactersInSet(CharacterSet.whitespaceAndNewline)
        
    }

    func containsCharacterFromSet(characterSet: Set<Character>) -> Bool {

        for character in characters {

            if characterSet.contains(character) {

                return false

            }

        }

        return true

    }

    func componentsSeparatedByCharactersInSet(characterSet: Set<Character>) -> [String] {

        return characters.split { characterSet.contains($0) }.map { String($0) }
        
    }

    func stringByTrimmingCharactersInSet(characterSet: Set<Character>) -> String {

        let string = stringByTrimmingFromStartCharactersInSet(characterSet)
        return string.stringByTrimmingFromEndCharactersInSet(characterSet)

    }

    private func stringByTrimmingFromStartCharactersInSet(characterSet: Set<Character>) -> String {

        var trimStartIndex: Int = characters.count

        for (index, character) in characters.enumerate() {

            if !characterSet.contains(character) {

                trimStartIndex = index
                break

            }

        }

        return self[startIndex.advancedBy(trimStartIndex) ..< endIndex]

    }

    private func stringByTrimmingFromEndCharactersInSet(characterSet: Set<Character>) -> String {

        var trimEndIndex: Int = characters.count

        for (index, character) in characters.reverse().enumerate() {

            if !characterSet.contains(character) {

                trimEndIndex = index
                break
                
            }

        }

        return self[startIndex ..< startIndex.advancedBy(characters.count - trimEndIndex)]

    }

    func substringWithRange(range: Range<Index>) -> String {

        return self[range]

    }

    func substringToIndex(index: Index) -> String {

        return self[startIndex ..< index]
        
    }

    func substringFromIndex(index: Index) -> String {

        return self[index ..< endIndex]

    }

}

struct CharacterSet {

    static var whitespaceAndNewline: Set<Character> {

        return [" ", "\n"]

    }

}

extension String {

    func integerFromHexadecimalString() -> Int? {

        struct Error : ErrorType {}

        let map = [
            "0": 0,  "1": 1,  "2": 2,  "3": 3,
            "4": 4,  "5": 5,  "6": 6,  "7": 7,
            "8": 8,  "9": 9,  "A": 10, "B": 11,
            "C": 12, "D": 13, "E": 14, "F": 15
        ]
        
        return try? uppercaseString.unicodeScalars.reduce(0) {

            let digitCharacter = String($1)
            guard let digit = map[digitCharacter] else { throw Error() }
            return $0 * 16 + digit

        }
        
    }

}

extension String {

    var base64Decode: String {

        let ascii: [UInt8] = [

            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
            52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
            64, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14,
            15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
            64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
            41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,

        ]

        var decoded: String = ""

        func appendCharacter(character: UInt8) {

            decoded.append(UnicodeScalar(character))

        }

        var unreadBytes = 0

        for character in utf8 {

            if ascii[Int(character)] > 63 { break }
            unreadBytes++

        }

        let encodedBytes = utf8.map { Int($0) }
        var index = 0

        while unreadBytes > 4 {

            appendCharacter(ascii[encodedBytes[index + 0]] << 2 | ascii[encodedBytes[index + 1]] >> 4)
            appendCharacter(ascii[encodedBytes[index + 1]] << 4 | ascii[encodedBytes[index + 2]] >> 2)
            appendCharacter(ascii[encodedBytes[index + 2]] << 6 | ascii[encodedBytes[index + 3]])

            index += 4
            unreadBytes -= 4

        }

        if unreadBytes > 1 {

            appendCharacter(ascii[encodedBytes[index + 0]] << 2 | ascii[encodedBytes[index + 1]] >> 4)

        }

        if unreadBytes > 2 {

            appendCharacter(ascii[encodedBytes[index + 1]] << 4 | ascii[encodedBytes[index + 2]] >> 2)

        }

        if unreadBytes > 3 {

            appendCharacter(ascii[encodedBytes[index + 2]] << 6 | ascii[encodedBytes[index + 3]])

        }

        return decoded

    }

    var base64Encode: String {

        let base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

        var encoded: String = ""

        func appendCharacterFromBase(character: Int) {

            encoded.append(base64[base64.startIndex.advancedBy(character)])

        }

        func appendCharacter(character: Character) {

            encoded.append(character)

        }

        let decodedBytes = utf8.map { Int($0) }

        var i = 0

        while i < decodedBytes.count - 2 {

            appendCharacterFromBase(( decodedBytes[i] >> 2) & 0x3F)
            appendCharacterFromBase(((decodedBytes[i]       & 0x3) << 4) | ((decodedBytes[i + 1] & 0xF0) >> 4))
            appendCharacterFromBase(((decodedBytes[i + 1]   & 0xF) << 2) | ((decodedBytes[i + 2] & 0xC0) >> 6))
            appendCharacterFromBase(  decodedBytes[i + 2]   & 0x3F)

            i += 3

        }

        if i < decodedBytes.count {

            appendCharacterFromBase((decodedBytes[i] >> 2) & 0x3F)

            if i == decodedBytes.count - 1 {

                appendCharacterFromBase(((decodedBytes[i] & 0x3) << 4))
                appendCharacter("=")

            } else {
                
                appendCharacterFromBase(((decodedBytes[i]     & 0x3) << 4) | ((decodedBytes[i + 1] & 0xF0) >> 4))
                appendCharacterFromBase(((decodedBytes[i + 1] & 0xF) << 2))
                
            }
            
            appendCharacter("=")
            
        }
        
        return encoded
        
    }

}
