// JSON.swift
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

public enum JSON {

    case NullValue
    case BooleanValue(Bool)
    case NumberValue(Double)
    case StringValue(String)
    case ArrayValue([JSON])
    case ObjectValue([String: JSON])

    static func from(value: Bool) -> JSON {

        return .BooleanValue(value)

    }

    static func from(value: Double) -> JSON {

        return .NumberValue(value)

    }

    static func from(value: String) -> JSON {

        return .StringValue(value)

    }

    static func from(value: [JSON]) -> JSON {

        return .ArrayValue(value)

    }

    static func from(value: [String: JSON]) -> JSON {

        return .ObjectValue(value)

    }

    public var boolValue: Bool {

        switch self {

        case .NullValue: return false
        case .BooleanValue(let b): return b
        default: return true

        }

    }

    public var doubleValue: Double {

        switch self {

        case .NumberValue(let n): return n
        case .StringValue(let s): return atof(s)
        case .BooleanValue(let b): return b ? 1.0 : 0.0
        default: return 0.0

        }

    }

    public var intValue: Int {

        return Int(doubleValue)

    }

    public var uintValue: UInt {

        return UInt(doubleValue)

    }

    public var stringValue: String {

        switch self {

        case .NullValue: return ""
        case .StringValue(let s): return s
        default: return description

        }

    }

    public var arrayValue: [JSON] {

        switch self {

        case .NullValue: return []
        case .ArrayValue(let array): return array
        default: return []

        }

    }

    public var dictionaryValue: [String: JSON] {

        switch self {

        case .NullValue: return [:]
        case .ObjectValue(let dictionary): return dictionary
        default: return [:]

        }

    }

    public subscript(index: UInt) -> JSON {

        set {

            switch self {

            case .ArrayValue(var a):
                if Int(index) < a.count {

                    a[Int(index)] = newValue
                    self = .ArrayValue(a)

                }

            default:
                break

            }

        }

        get {

            switch self {

            case .ArrayValue(let a):
                return Int(index) < a.count ? a[Int(index)] : .NullValue

            default:
                return .NullValue

            }

        }

    }

    public subscript(key: String) -> JSON {

        set {

            switch self {

            case .ObjectValue(var o):
                o[key] = newValue
                self = .ObjectValue(o)

            default:
                break
                
            }

        }

        get {

            switch self {

            case .ObjectValue(let o):
                return o[key] ?? .NullValue

            default:
                return .NullValue

            }

        }

    }

    public func serialize(serializer: JSONSerializer) -> String {

        return serializer.serialize(self)

    }

}

extension JSON: CustomStringConvertible {

    public var description: String {

        return serialize(DefaultJSONSerializer())

    }

}

extension JSON: CustomDebugStringConvertible {

    public var debugDescription: String {

        return serialize(PrettyJSONSerializer())

    }

}

extension JSON: Equatable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {

    switch lhs {

    case .NullValue:

        switch rhs {

        case .NullValue:
            return true

        default:
            return false

        }

    case .BooleanValue(let lhsValue):

        switch rhs {

        case .BooleanValue(let rhsValue):
            return lhsValue == rhsValue

        default:
            return false

        }

    case .StringValue(let lhsValue):

        switch rhs {

        case .StringValue(let rhsValue):
            return lhsValue == rhsValue

        default:
            return false

        }

    case .NumberValue(let lhsValue):

        switch rhs {

        case .NumberValue(let rhsValue):
            return lhsValue == rhsValue

        default:
            return false

        }

    case .ArrayValue(let lhsValue):

        switch rhs {

        case .ArrayValue(let rhsValue):
            return lhsValue == rhsValue

        default:
            return false

        }

    case .ObjectValue(let lhsValue):

        switch rhs {

        case .ObjectValue(let rhsValue):
            return lhsValue == rhsValue

        default:
            return false

        }

    }

}

extension JSON: NilLiteralConvertible {

    public init(nilLiteral value: Void) {

        self = .NullValue

    }

}

extension JSON: BooleanLiteralConvertible {

    public init(booleanLiteral value: BooleanLiteralType) {

        self = .BooleanValue(value)

    }

}

extension JSON: IntegerLiteralConvertible {

    public init(integerLiteral value: IntegerLiteralType) {

        self = .NumberValue(Double(value))

    }

}

extension JSON: FloatLiteralConvertible {

    public init(floatLiteral value: FloatLiteralType) {

        self = .NumberValue(Double(value))
        
    }
    
}

extension JSON: StringLiteralConvertible {
    
    public typealias UnicodeScalarLiteralType = String
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        
        self = .StringValue(value)
        
    }
    
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
        
        self = .StringValue(value)
        
    }
    
    public init(stringLiteral value: StringLiteralType) {
        
        self = .StringValue(value)
        
    }
    
}

extension JSON: ArrayLiteralConvertible {
    
    public init(arrayLiteral elements: JSON...) {
        
        self = .ArrayValue(elements)
        
    }
    
}

extension JSON: DictionaryLiteralConvertible {
    
    public init(dictionaryLiteral elements: (String, JSON)...) {
        
        var dictionary = [String: JSON](minimumCapacity: elements.count)
        
        for pair in elements {
            
            dictionary[pair.0] = pair.1
            
        }
        
        self = .ObjectValue(dictionary)
        
    }
    
}