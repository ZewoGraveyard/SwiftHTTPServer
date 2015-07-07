// Regex.swift
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

typealias CompiledRegex = regex_t
typealias RegexMatch = regmatch_t

struct RegularExpression {

    enum CompileRegexResult {

        case Success
        case InvalidRepetitionCount
        case InvalidRegularExpression
        case InvalidRepetitionOperand
        case InvalidCollatingElement
        case InvalidCharacterClass
        case TrailingBackslash
        case InvalidBackreferenceNumber
        case UnbalancedBrackets
        case UnbalancedParentheses
        case UnbalancedBraces
        case InvalidCharacterRange
        case OutOfMemory
        case UnrecognizedError

        init(code: Int32) {

            switch code {

            case 0: self = Success
            case REG_BADBR: self = InvalidRepetitionCount
            case REG_BADPAT: self = InvalidRegularExpression
            case REG_BADRPT: self = InvalidRepetitionOperand
            case REG_ECOLLATE: self = InvalidCollatingElement
            case REG_ECTYPE: self = InvalidCharacterClass
            case REG_EESCAPE: self = TrailingBackslash
            case REG_ESUBREG: self = InvalidBackreferenceNumber
            case REG_EBRACK: self = UnbalancedBrackets
            case REG_EPAREN: self = UnbalancedParentheses
            case REG_EBRACE: self = UnbalancedBraces
            case REG_ERANGE: self = InvalidCharacterRange
            case REG_ESPACE: self = OutOfMemory
            default: self = UnrecognizedError

            }

        }

        // better error with http://codepad.org/X1Qb8kfc

        var failure: ErrorType? {

            switch self {

            case Success: return .None
            case InvalidRepetitionCount: return Error.Generic("Could not compile regex", "Invalid Repetition Count")
            case InvalidRegularExpression: return Error.Generic("Could not compile regex", "Invalid Regular Expression")
            case InvalidRepetitionOperand: return Error.Generic("Could not compile regex", "Invalid Repetition Operand")
            case InvalidCollatingElement: return Error.Generic("Could not compile regex", "Invalid Collating Element")
            case InvalidCharacterClass: return Error.Generic("Could not compile regex", "Invalid Character Class")
            case TrailingBackslash: return Error.Generic("Could not compile regex", "Trailing Backslash")
            case InvalidBackreferenceNumber: return Error.Generic("Could not compile regex", "Invalid Backreference Number")
            case UnbalancedBrackets: return Error.Generic("Could not compile regex", "Unbalanced Brackets")
            case UnbalancedParentheses: return Error.Generic("Could not compile regex", "Unbalanced Parentheses")
            case UnbalancedBraces: return Error.Generic("Could not compile regex", "Unbalanced Braces")
            case InvalidCharacterRange: return Error.Generic("Could not compile regex", "Invalid Character Range")
            case OutOfMemory: return Error.Generic("Could not compile regex", "Out Of Memory")
            case UnrecognizedError: return Error.Generic("Could not compile regex", "Unrecognized Error")
                
            }


        }

    }

    struct CompileRegexOptions: OptionSetType {

        let rawValue: Int32

        static let Basic =                    CompileRegexOptions(rawValue: REG_BASIC)
        static let Extended =                 CompileRegexOptions(rawValue: REG_EXTENDED)
        static let CaseInsensitive =          CompileRegexOptions(rawValue: REG_ICASE)
        static let ResultOnly =               CompileRegexOptions(rawValue: REG_NOSUB)
        static let NewLineSensitive =         CompileRegexOptions(rawValue: REG_NEWLINE)

    }

    enum MatchRegexResult {

        case Success
        case NoMatch
        case OutOfMemory

        init(code: Int32) {

            switch code {

            case 0: self = Success
            case REG_NOMATCH: self = NoMatch
            case REG_ESPACE: self = OutOfMemory
            default: fatalError()

            }

        }

        var failure: ErrorType? {

            switch self {

            case OutOfMemory: return Error.Generic("Could not match regex", "Out Of Memory")
            default: return .None

            }
            
        }

        var didMatch: Bool {

            switch self {

            case Success: return true
            default: return false

            }

        }
        
    }

    struct MatchRegexOptions: OptionSetType {

        let rawValue: Int32

        static let FirstCharacterNotAtBeginningOfLine = CompileRegexOptions(rawValue: REG_NOTBOL)
        static let LastCharacterNotAtEndOfLine =        CompileRegexOptions(rawValue: REG_NOTEOL)
        
    }

    let pattern: String
    let regex: CompiledRegex

    init(pattern: String) throws {

        self.pattern = pattern
        self.regex = try RegularExpression.compileRegex(pattern)

    }

    func groups(string: String) throws -> [String] {

        return try RegularExpression.groups(regex, string: string)

    }

    func matches(string: String) throws -> Bool {

        return try RegularExpression.matches(regex, string: string)
        
    }

    func replace(string: String, withTemplate template: String) throws -> String {

        return try RegularExpression.replace(regex, string: string, template: template)

    }

}

// MARK: Private

extension RegularExpression {

    private static func compileRegex(pattern: String, options: CompileRegexOptions = [.Extended]) throws -> CompiledRegex {

        var regex = CompiledRegex()
        let result = CompileRegexResult(code: regcomp(&regex, pattern, options.rawValue))

        if let error = result.failure {

            throw error

        } else {

            return regex

        }

    }

    private static func matches(regex: CompiledRegex, string: String, maxNumberOfMatches: Int = 10, options: MatchRegexOptions = []) throws -> Bool {

        let firstMatch = try RegularExpression.firstMatch(regex, string: string, maxNumberOfMatches: maxNumberOfMatches, options: options)

        if firstMatch != nil {

            return true

        }
        
        return false
        
    }

    private static func groups(regex: CompiledRegex, var string: String, maxNumberOfMatches: Int = 10, options: MatchRegexOptions = []) throws -> [String] {

        var allGroups: [String] = []

        while let regexMatches = try RegularExpression.firstMatch(regex, string: string, maxNumberOfMatches: maxNumberOfMatches, options: options) {

            allGroups += RegularExpression.getGroups(regexMatches, string: string)
            let regexMatch = regexMatches.first!
            let endOfMatchIndex = advance(string.startIndex, Int(regexMatch.rm_eo))
            string = string[endOfMatchIndex ..< string.endIndex]

        }

        return allGroups

    }

    private static func firstMatch(var regex: CompiledRegex, string: String, maxNumberOfMatches: Int = 10, options: MatchRegexOptions = []) throws -> [RegexMatch]? {

        let regexMatches = [RegexMatch](count: maxNumberOfMatches, repeatedValue: RegexMatch())

        let code = regexec(&regex, string, maxNumberOfMatches, UnsafeMutablePointer<RegexMatch>(regexMatches), options.rawValue)

        let result = MatchRegexResult(code: code)

        if let error = result.failure {

            throw error

        }

        if result.didMatch {

            return regexMatches

        } else {

            return .None

        }

    }

    private static func getGroups(regexMatches: [RegexMatch], string: String) -> [String] {

        var groups: [String] = []

        if regexMatches.count <= 1 {

            return []

        }

        for var index = 1; regexMatches[index].rm_so != -1; index++ {

            let regexMatch = regexMatches[index]
            let range = getRange(regexMatch, string: string)
            let match = string[range]

            groups.append(match)
            
        }

        return groups

    }

    // TODO: fix bug where it doesn't find a match

    private static func replace(regex: CompiledRegex, var string: String, template: String, maxNumberOfMatches: Int = 10, options: MatchRegexOptions = []) throws -> String {

        var totalReplacedString: String = ""

        while let regexMatches = try RegularExpression.firstMatch(regex, string: string, maxNumberOfMatches: maxNumberOfMatches, options: options) {

            let regexMatch = regexMatches.first!
            let endOfMatchIndex = advance(string.startIndex, Int(regexMatch.rm_eo))

            var replacedString = RegularExpression.replaceMatch(regexMatch, string: string, withTemplate: template)

            let templateDelta = template.utf8.count - (regexMatch.rm_eo - regexMatch.rm_so)
            let templateDeltaIndex = advance(replacedString.startIndex, Int(regexMatch.rm_eo + templateDelta))

            replacedString = replacedString[replacedString.startIndex ..< templateDeltaIndex]

            totalReplacedString += replacedString

            string = string[endOfMatchIndex ..< string.endIndex]
            
        }
        
        return totalReplacedString + string
        
    }

    private static func replaceMatch(regexMatch: RegexMatch, var string: String, withTemplate template: String) -> String {

        let range = getRange(regexMatch, string: string)
        string.replaceRange(range, with: template)
        return string
        
    }

    private static func getRange(regexMatch: RegexMatch, string: String) -> Range<String.Index> {

        let start = advance(string.startIndex, Int(regexMatch.rm_so))
        let end = advance(string.startIndex, Int(regexMatch.rm_eo))

        return start ..< end
        
    }

}