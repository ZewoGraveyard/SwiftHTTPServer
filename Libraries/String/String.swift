// String.swift
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

struct FormatAttribute {
    let argIndex: Int?
    let flags: UInt // bit vector
    let minWidth: Int
    let precisionOrMaxWidth: Int


    var hasSpacePrefixFlag: Bool {
        return flags & FillingFlag.SPACE_PREFIX.rawValue != 0
    }

    var hasPlusPrefixFlag: Bool {
        return flags & FillingFlag.PLUS_PREFIX.rawValue != 0
    }

    var hasLeftJustifyFlag: Bool {
        return flags & FillingFlag.LEFT_JUSTIFY.rawValue != 0
    }

    var hasBinaryPrefix: Bool {
        return flags & FillingFlag.BINARY_PREFIX.rawValue != 0
    }

    var filling: Character {
        return flags & FillingFlag.ZERO.rawValue != 0 ? "0" : " "
    }

    var numberPrefix: String {
        if flags & FillingFlag.PLUS_PREFIX.rawValue != 0 {
            return "+"
        } else if flags & FillingFlag.SPACE_PREFIX.rawValue != 0 {
            return " "
        } else {
            return ""
        }
    }

    func intToString<T: IntegerType>(a: T) -> String {
        if a > 0 {
            return numberPrefix + "\(a)"
        } else {
            return "\(a)"
        }
    }

    // This is not a generic function that handles FloatingPointType;
    // this is because Float80 doesn't confirm FloatingPointType as of Swift 1.1
    func floatToString(a: Double) -> String {
        let fractionPart = abs(a % 1.0)
        let intPart = IntMax(a)

        if precisionOrMaxWidth == Int.max {
            // as possible as natural
            if fractionPart == 0.0 {
                return intToString(intPart)
            } else {
                if a.isSignMinus {
                    return "\(a)"
                } else {
                    return numberPrefix + "\(a)"
                }
            }
        } else {
            let f = makeFractionString(fractionPart)
            if a.isSignMinus {
                return "\(intPart).\(f)"
            } else {
                return numberPrefix + "\(intPart).\(f)"
            }
        }
    }

    func makeFractionString(fractionPart: Double) -> String {
        let v = fractionPart * pow(10, Double(precisionOrMaxWidth))
        return "\(IntMax(v))"
    }

    func fill(s: String) -> String {
        let w = s.characters.count // XXX: should use visual width?

        if hasLeftJustifyFlag {
            // use a space for filling in left-jusitfy mode
            return s + String(count: max(minWidth - w, 0), repeatedValue: Character(" "))
        } else {
            // right-justify mode
            return String(count: max(minWidth - w, 0), repeatedValue: filling) + s
        }
    }
}

enum FillingFlag: UInt {
    case SPACE_PREFIX  = 0b00000001
    case PLUS_PREFIX   = 0b00000010
    case LEFT_JUSTIFY  = 0b00000100
    case ZERO          = 0b00001000
    case BINARY_PREFIX = 0b00010000

    init?(_ c: Character) {
        switch c {
        case " ":
            self = .SPACE_PREFIX
        case "+":
            self = .PLUS_PREFIX
        case "-":
            self = .LEFT_JUSTIFY
        case "0":
            self = .ZERO
        case "#":
            self = .BINARY_PREFIX
        default:
            return nil
        }
    }
}

public struct StringFormatter {

    typealias SourceType = String

    let template: SourceType
    let args: [Any?]
    let nilToken: String

    init(template: SourceType, args: [Any?], nilToken: String) {
        self.template = template
        self.args = args
        self.nilToken = nilToken
    }

    func process() -> String {
        var result = ""

        var argIndex = 0

        var i = template.startIndex
        let endIndex = template.endIndex
        while i != endIndex {
            switch template[i] {
            case "%":
                let (s, nextIndex, nextArgIndex) = processDirective(i.successor(), argIndex)
                result += s
                i = nextIndex
                argIndex = nextArgIndex
            case (let c):
                result.append(c)
                i++
            }
        }
        return result
    }

    func processDirective(index: SourceType.Index, _ argIndex: Int) -> (String, SourceType.Index, Int) {
        if template[index] == "%" {
            return ("%", index.successor(), argIndex)
        }

        var i = index

        // format attributes
        let attr = processAttribute(&i)
        var a: Int
        var nextArgIndex: Int
        if let v = attr.argIndex {
            a = v
            nextArgIndex = argIndex
        } else {
            a = argIndex
            nextArgIndex = argIndex.successor()
        }

        // dispatch by argument type

        switch template[i] {
        case "s", "@" /* ok? */:
            return (toString(attr, args[a]), i.successor(), nextArgIndex)
        case "d":
            return (toDecimalString(attr, args[a]), i.successor(), nextArgIndex)
        case "f":
            return (toFloatString(attr, args[a]), i.successor(), nextArgIndex)
        case (let c):
            fatalError("Unexpected template format: \(c)")
        }
    }

    func processAttribute(inout i: SourceType.Index) -> FormatAttribute {
        let (argIndex, flags, minWidth) = processAttribute0(&i)

        var precisionOrMaxWidth = Int.max
        if template[i] == "." {
            i++
            precisionOrMaxWidth = 0
            if let v = readInt(&i) {
                precisionOrMaxWidth = v
            }
        }

        return FormatAttribute(argIndex: argIndex, flags: flags, minWidth: minWidth, precisionOrMaxWidth: precisionOrMaxWidth)
    }

    func processAttribute0(inout i: SourceType.Index) -> (Int?, UInt, Int) {
        var minWidth = 0
        var argIndex: Int? = nil

        // optional argument index (or min width)
        if let v = readInt(&i) {
            if template[i] == "$" { // argument index
                i++
                argIndex = v - 1 // argument index is 1 origin
            } else {
                return (nil, 0, v)
            }
        }

        // format flags

        var flags: UInt = 0
        while let f = FillingFlag(template[i]) {
            flags |= f.rawValue
            i++
        }

        if let v = readInt(&i) {
            minWidth = v
        }

        return (argIndex, flags, minWidth)
    }


    func charToInt(c: Character) -> Int {
        return Int(String(c)) ?? 0
    }


    func readInt(inout i: SourceType.Index) -> Int? {
        var value = 0
        switch template[i] {
        case let c where ("1" ... "9").contains(c):
            value = charToInt(c)
            i++
        default:
            return nil
        }
        DECIMAL_VALUES: while true {
            switch template[i] {
            case let c where ("0" ... "9").contains(c):
                value = value * 10 + charToInt(c)
                i++
            default:
                break DECIMAL_VALUES
            }
        }

        return value
    }


    func toString(attr: FormatAttribute, _ a: Any?) -> String {
        let s = attr.fill("\(a ?? nilToken)")

        // truncate by max width; O(maxWidth)
        if attr.precisionOrMaxWidth != Int.max {
            var end = s.startIndex
            var maxWidth = attr.precisionOrMaxWidth
            while end != s.endIndex && maxWidth != 0 {
                end++
                maxWidth--
            }
            return s[s.startIndex ..< end]
        } else {
            return s
        }
    }

    func toDecimalString(attr: FormatAttribute, _ a: Any?) -> String {
        switch a ?? 0 {
        case let v as Int:
            return attr.fill(attr.intToString(v))
        case let v as IntMax:
            return attr.fill(attr.intToString(v))
        case let v as Float:
            return toDecimalString(attr, IntMax(v))
        case let v as Double:
            return toDecimalString(attr, IntMax(v))
        case let v as Float80:
            return toDecimalString(attr, IntMax(v))
        case let v:
            return toDecimalString(attr, atoll("\(v)"))
        }
    }

    func toFloatString(attr: FormatAttribute, _ a: Any?) -> String {
        switch a ?? 0.0 {
        case let v as Int:
            return toFloatString(attr, Double(v))
        case let v as IntMax:
            return toFloatString(attr, Float80(v))
        case let v as Float:
            return attr.fill(attr.floatToString(Double(v)))
        case let v as Double:
            return attr.fill(attr.floatToString(v))
        case let v:
            return toFloatString(attr, atof("\(v)"))
        }
    }
}

extension String {

    init(format: String, _ args: Any?...) {
    
        let formatter = StringFormatter(template: format, args: args, nilToken: "(nil)")
        self.init( formatter.process())

    }
    
}









extension String {

    init?(data: Data) {

        self.init(bytes: data.bytes)

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

        var encodedArray: [UInt8] = bytes
        var decodedArray: [UInt8] = []

        for var index = 0; index < encodedArray.count; {

            let codeUnit = encodedArray[index]

            if codeUnit == 37 {

                let unicodeA = UnicodeScalar(encodedArray[index+1])
                let unicodeB = UnicodeScalar(encodedArray[index+2])

                let s = "\(unicodeA)\(unicodeB)"
                let z = hexToInt(s)

                decodedArray.append(z)

                index += 3

            } else if codeUnit == 43 {

                decodedArray.append(32)
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

        return String(dropFirst(self.characters))

    }

    func dropLastCharacter() -> String {

        return String(dropLast(self.characters))
        
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

        var i = distance(self.startIndex, startIndex)

        while i <= self.characters.count - string.characters.count {

            if self[advance(self.startIndex, i)..<advance(self.startIndex, i+string.characters.count)] == string {

                ranges.append(Range(start:advance(self.startIndex, i),end:advance(self.startIndex, i+string.characters.count)))
                i = i+string.characters.count

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

        return split(characters, allowEmptySlices: allowEmptySlices) { $0 == separator }.map { String($0) }

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

        return split(characters) { characterSet.contains($0) }.map { String($0) }
        
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

        return self[advance(startIndex, trimStartIndex) ..< endIndex]

    }

    private func stringByTrimmingFromEndCharactersInSet(characterSet: Set<Character>) -> String {

        var trimEndIndex: Int = characters.count

        for (index, character) in characters.reverse().enumerate() {

            if !characterSet.contains(character) {

                trimEndIndex = index
                break
                
            }

        }

        return self[startIndex ..< advance(startIndex, characters.count - trimEndIndex)]

    }

    func substringWithRange(range: Range<Index>) -> String {

        return self[range]

    }

    func substringFromIndex(index: Index) -> String {

        return self[index ..< endIndex]

    }

    func replaceOccurrencesOfString(string: String, withString replaceString: String) -> String {

        do {
            let regularExpression = try RegularExpression(pattern: string)
            return try regularExpression.replace(self, withTemplate: replaceString)

        } catch {

            return self

        }

    }

}

struct CharacterSet {

    static var whitespaceAndNewline: Set<Character> {

        return [" ", "\n"]

    }

}

func hexToInt(hex: String) -> UInt8 {

    let map = [

        "0": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4": 4,
        "5": 5,
        "6": 6,
        "7": 7,
        "8": 8,
        "9": 9,
        "A": 10,
        "B": 11,
        "C": 12,
        "D": 13,
        "E": 14,
        "F": 15
        
    ]
    
    let total = hex.uppercaseString.unicodeScalars.reduce(0) { $0 * 16 + (map[String($1)] ?? 0xff) }
    
    if total > 0xFF {
        
        assertionFailure("Input char was wrong")
        
    }
    
    return UInt8(total)
    
}
