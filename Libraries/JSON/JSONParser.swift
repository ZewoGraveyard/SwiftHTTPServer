// JSONParser.swift
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

public struct JSONParser {

    public static func parse(source: String) throws -> JSON {

        return try GenericJSONParser(source.utf8).parse()

    }

    public static func parse(source: [UInt8]) throws -> JSON {

        return try GenericJSONParser(source).parse()

    }

}

public class GenericJSONParser<ByteSequence: CollectionType where ByteSequence.Generator.Element == UInt8>: Parser {

    public typealias Source = ByteSequence
    typealias Char = Source.Generator.Element

    let source: Source
    var cur: Source.Index
    let end: Source.Index

    public var lineNumber = 1
    public var columnNumber = 1

    public init(_ source: Source) {

        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex

    }

    public func parse() throws -> JSON {

        let JSON = try parseValue()

        skipWhitespaces()

        if (cur == end) {

            return JSON

        } else {

            throw JSONParseError.ExtraTokenError("extra tokens found", self)

        }

    }

}

// MARK: - Private

extension GenericJSONParser {

    private func parseValue() throws -> JSON {

        skipWhitespaces()

        if cur == end {

            throw JSONParseError.InsufficientTokenError("unexpected end of tokens", self)

        }

        switch currentChar {

        case Char(ascii: "n"):
            return try parseSymbol("null", JSON.NullValue)

        case Char(ascii: "t"):
            return try parseSymbol("true", JSON.BooleanValue(true))

        case Char(ascii: "f"):
            return try parseSymbol("false", JSON.BooleanValue(false))

        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"):
            return try parseNumber()

        case Char(ascii: "\""):
            return try parseString()

        case Char(ascii: "{"):
            return try parseObject()

        case Char(ascii: "["):
            return try parseArray()

        case (let c):
            throw JSONParseError.UnexpectedTokenError("unexpected token: \(c)", self)

        }

    }

    private var currentChar: Char {

        return source[cur]

    }

    private var nextChar: Char {

        return source[cur.successor()]

    }

    private var currentSymbol: Character {

        return Character(UnicodeScalar(currentChar))

    }

    private func parseSymbol(target: StaticString, @autoclosure _ iftrue:  () -> JSON) throws -> JSON {

        if expect(target) {

            return iftrue()

        } else {

            throw JSONParseError.UnexpectedTokenError("expected \"\(target)\" but \(currentSymbol)", self)

        }

    }

    private func parseString() throws -> JSON {

        assert(currentChar == Char(ascii: "\""), "points a double quote")
        advance()

        var buffer: [CChar] = []

        LOOP: for ; cur != end; advance() {

            switch currentChar {

            case Char(ascii: "\\"):

                advance()

                if (cur == end) {

                    throw JSONParseError.InvalidStringError("unexpected end of a string literal", self)

                }

                if let c = parseEscapedChar() {

                    for u in String(c).utf8 {

                        buffer.append(CChar(bitPattern: u))

                    }

                } else {

                    throw JSONParseError.InvalidStringError("invalid escape sequence", self)

                }

                break

            case Char(ascii: "\""): // end of the string literal
                break LOOP

            default:
                buffer.append(CChar(bitPattern: currentChar))

            }

        }

        if !expect("\"") {

            throw JSONParseError.InvalidStringError("missing double quote", self)

        }

        buffer.append(0) // trailing nul

        let s = String.fromCString(buffer)!
        return .StringValue(s)

    }

    private func parseEscapedChar() -> UnicodeScalar? {

        let c = UnicodeScalar(currentChar)

        if c == "u" { // Unicode escape sequence

            var length = 0 // 2...8
            var value: UInt32 = 0

            while let d = hexToDigit(nextChar) {

                advance()
                length++

                if length > 8 {

                    break

                }

                value = (value << 4) | d

            }

            if length < 2 {

                return nil

            }
            // TODO: validate the value
            return UnicodeScalar(value)

        } else {

            let c = UnicodeScalar(currentChar)
            return unescapeMapping[c] ?? c

        }

    }

    // number = [ minus ] int [ frac ] [ exp ]
    private func parseNumber() throws -> JSON {

        let sign = expect("-") ? -1.0 : 1.0

        var integer: Int64 = 0

        switch currentChar {

        case Char(ascii: "0"):
            advance()

        case Char(ascii: "1") ... Char(ascii: "9"):

            for ; cur != end; advance() {

                if let value = digitToInt(currentChar) {

                    integer = (integer * 10) + Int64(value)

                } else {

                    break

                }

            }

        default:
            throw JSONParseError.InvalidNumberError("invalid token in number", self)

        }

        if integer != Int64(Double(integer)) {
            // TODO
            //return .Error(InvalidNumberError("too much integer part in number", self))
        }

        var fraction: Double = 0.0

        if expect(".") {

            var factor = 0.1
            var fractionLength = 0

            for ; cur != end; advance() {

                if let value = digitToInt(currentChar) {

                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength++

                } else {

                    break

                }

            }

            if fractionLength == 0 {

                throw JSONParseError.InvalidNumberError("insufficient fraction part in number", self)

            }

        }

        var exponent: Int64 = 0

        if expect("e") || expect("E") {

            var expSign: Int64 = 1

            if expect("-") {

                expSign = -1

            } else if expect("+") {

                // do nothing

            }

            exponent = 0

            var exponentLength = 0

            for ; cur != end; advance() {

                if let value = digitToInt(currentChar) {

                    exponent = (exponent * 10) + Int64(value)
                    exponentLength++

                } else {

                    break

                }

            }

            if exponentLength == 0 {

                throw JSONParseError.InvalidNumberError("insufficient exponent part in number", self)

            }

            exponent *= expSign

        }

        return .NumberValue(sign * (Double(integer) + fraction) * pow(10, Double(exponent)))

    }

    private func parseObject() throws -> JSON {

        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        advance()
        skipWhitespaces()

        var object: [String: JSON] = [:]

        LOOP: while cur != end && !expect("}") {

            let keyValue = try parseValue()

            switch keyValue {

            case .StringValue(let key):

                skipWhitespaces()

                if !expect(":") {

                    throw JSONParseError.UnexpectedTokenError("missing colon (:)", self)

                }

                skipWhitespaces()

                let value = try parseValue()

                object[key] = value

                skipWhitespaces()

                if expect(",") {

                    break

                } else if expect("}") {

                    break LOOP

                } else {

                    throw JSONParseError.UnexpectedTokenError("missing comma (,)", self)

                }

            default:
                throw JSONParseError.NonStringKeyError("unexpected value for object key", self)

            }

        }

        return .ObjectValue(object)

    }

    private func parseArray() throws -> JSON {

        assert(currentChar == Char(ascii: "["), "points \"[\"")
        advance()
        skipWhitespaces()

        var array: [JSON] = []

        LOOP: while cur != end && !expect("]") {

            let JSON = try parseValue()

            skipWhitespaces()
            
            array.append(JSON)
            
            if expect(",") {

                continue
                
            } else if expect("]") {
                
                break LOOP
                
            } else {
                
                throw JSONParseError.UnexpectedTokenError("missing comma (,) (token: \(currentSymbol))", self)
                
            }
            
        }
        
        return .ArrayValue(array)
        
    }
    
    
    private func expect(target: StaticString) -> Bool {
        
        if cur == end {
            
            return false
            
        }
        
        if !isIdentifier(target.utf8Start.memory) {
            
            // when single character
            if target.utf8Start.memory == currentChar {
                
                advance()
                return true
                
            } else {
                
                return false
                
            }
            
        }
        
        let start = cur
        let l = lineNumber
        let c = columnNumber
        
        var p = target.utf8Start
        let endp = p.advancedBy(Int(target.byteSize))
        
        for ; p != endp; p++, advance() {
            
            if p.memory != currentChar {
                
                cur = start // unread
                lineNumber = l
                columnNumber = c
                return false
                
            }
            
        }
        
        return true
        
    }
    
    // only "true", "false", "null" are identifiers
    private func isIdentifier(char: Char) -> Bool {
        
        switch char {

        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
            
        default:
            return false
            
        }
        
    }
    
    private func advance() {
        
        assert(cur != end, "out of range")
        cur++
        
        if cur != end {
            
            switch currentChar {
                
            case Char(ascii: "\n"):
                lineNumber++
                columnNumber = 1
                
            default:
                columnNumber++
                
            }
            
        }
        
    }
    
    private func skipWhitespaces() {
        
        for ; cur != end; advance() {
            
            switch currentChar {
                
            case Char(ascii: " "), Char(ascii: "\t"), Char(ascii: "\r"), Char(ascii: "\n"):
                break
                
            default:
                return
                
            }
            
        }
        
    }
    
}
