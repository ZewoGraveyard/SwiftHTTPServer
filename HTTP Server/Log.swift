// Log.swift
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

struct Log {

    // MARK: - Levels

    struct Levels: OptionSetType {

        let rawValue: Int32

        static let Trace   = Levels(rawValue: 1 << 0)
        static let Debug   = Levels(rawValue: 1 << 1)
        static let Info    = Levels(rawValue: 1 << 2)
        static let Warning = Levels(rawValue: 1 << 3)
        static let Error   = Levels(rawValue: 1 << 4)
        static let Fatal   = Levels(rawValue: 1 << 5)
        
    }

    static var levels: Levels = [.Trace, .Debug, .Info, .Warning, .Error, .Fatal]

    // MARK: - Colors

    static var colorsEnabled: Bool {

        let xcodeColors = getenv("XcodeColors")

        if let enabled = String.fromCString(xcodeColors) where enabled == "YES" {

            return true

        }
        
        return false
        
    }

    static let escape = "\u{001b}["
    
    static let resetForeground = escape + "fg;"
    static let resetBackground = escape + "bg;"
    static let reset = escape + ";"
    
    static let lightBlue = escape + "fg33,183,195;"

    static let red = escape + "fg179,67,62;"

    //static let darkPurple = escape + "fg89,87,185;"
    static let darkPurple = escape + "fg60,58,123;"
    static let purple = escape + "fg97,92,168;"
    //static let lightPurple = escape + "fg118,112,205;"
    static let lightPurple = escape + "fg139,110,255;"

    static let darkGreen = escape + "fg55,86,66;"
    static let green = escape + "fg82,128,97;"
    static let lightGreen = escape + "fg96,172,127;"

}

// MARK: - Public

extension Log {

    private static func log<T>(object: T, color: String) {

        if colorsEnabled {

            print("\(color)\(object)\(reset)")

        } else {

            print(object)

        }

    }

    static func trace<T>(object: T) {

        if levels.contains(.Trace) {

            log("\(object)", color: red)

        }
        
    }

    static func debug<T>(object: T) {

        if levels.contains(.Debug) {

            log("\(object)", color: red)

        }
        
    }

    static func info<T>(object: T) {

        if levels.contains(.Info) {

            log("\(object)", color: lightGreen)

        }
        
    }

    static func warning<T>(object: T) {

        if levels.contains(.Warning) {

            log("\(object)", color: red)

        }
        
    }

    static func error<T>(object: T) {

        if levels.contains(.Error) {

            log("\(object)", color: red)

        }

    }

    static func fatal<T>(object: T) {

        if levels.contains(.Fatal) {

            log("\(object)", color: red)

        }
        
    }

}

protocol CustomColorLogStringConvertible {

    var logDescription: String { get }
    
}

extension Log {

    private static func customColorLog(object: CustomColorLogStringConvertible) {

        if colorsEnabled {

            print(object.logDescription)

        } else {

            print(object)
            
        }
        
    }

    static func trace(object: CustomColorLogStringConvertible) {

        if levels.contains(.Trace) {

            customColorLog(object)

        }
        
    }

    static func debug(object: CustomColorLogStringConvertible) {

        if levels.contains(.Debug) {

            customColorLog(object)

        }
        
    }

    static func info(object: CustomColorLogStringConvertible) {

        if levels.contains(.Info) {

            customColorLog(object)

        }
        
    }

    static func warning(object: CustomColorLogStringConvertible) {

        if levels.contains(.Warning) {

            customColorLog(object)

        }
        
    }

    static func error(object: CustomColorLogStringConvertible) {

        if levels.contains(.Error) {

            customColorLog(object)

        }
        
    }

    static func fatal(object: CustomColorLogStringConvertible) {

        if levels.contains(.Fatal) {

            customColorLog(object)

        }
        
    }
    
}