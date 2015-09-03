// Result.swift
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

import Foundation

// MARK: - Result

public enum Result<T> {

    case Success(T)
    case Failure([ErrorType])

    public init(value: T) {

        self = .Success(value)

    }

    public init(errors: [ErrorType]) {

        self = .Failure(errors)

    }

    public init(error: ErrorType) {

        self = .Failure([error])
        
    }

}

// MARK: - Unwrappers

extension Result {

    public var value: T? {

        switch self {

        case .Success(let value):
            return value

        case .Failure(_):
            return .None

        }

    }

    public var succeeded: Bool {

        switch self {

        case .Success(_):
            return true

        case .Failure(_):
            return false

        }

    }

    public var errors: [ErrorType]? {

        switch self {

        case .Success(_):
            return .None

        case .Failure(let errors):
            return errors

        }

    }

    public var failed: Bool {

        switch self {

        case .Success(_):
            return false

        case .Failure(_):
            return true

        }

    }

}

public func strive<T>(@noescape f: Void throws -> T?) -> Result<T> {

    return Result<T>.strive(f)
    
}

public func strive<T>(completion: Result<T> -> Void, runQueue: DispatchQueue = Dispatch.defaultQueue, resultQueue: DispatchQueue = Dispatch.mainQueue, f: Void throws -> T?) {

    Dispatch.async(queue: runQueue) {

        let result = Result<T>.strive(f)

        Dispatch.async(queue: resultQueue) {

            completion(result)
            
        }
        
    }

}

public func strive<T>(@noescape f: (ErrorType -> T?) throws -> T?) -> Result<T> {

    return Result<T>.strive(f)
    
}

public func strive<T>(completion: Result<T> -> Void, runQueue: DispatchQueue = Dispatch.defaultQueue, resultQueue: DispatchQueue = Dispatch.mainQueue, f: (ErrorType -> T?) throws -> T?) {

    Dispatch.async(queue: runQueue) {

        let result = Result<T>.strive(f)

        Dispatch.async(queue: resultQueue) {

            completion(result)

        }
        
    }
    
}

public func strive<T>(completion: Result<T> -> Void, runQueue: DispatchQueue = Dispatch.defaultQueue, resultQueue: DispatchQueue = Dispatch.mainQueue, f: (T -> Void) throws -> Void) {

    Dispatch.async(queue: runQueue) {

        let result = Result<T>.strive(f)

        Dispatch.async(queue: resultQueue) {

            completion(result)
            
        }
        
    }
    
}

public func strive<T>(
    completion: Result<T> -> Void,
    runQueue: DispatchQueue = Dispatch.defaultQueue,
    resultQueue: DispatchQueue = Dispatch.mainQueue,
    f: ((success: (T -> Void), failure: (ErrorType -> Void)) throws -> Void)) {

    let s = { (v: T) in

        Dispatch.async(queue: resultQueue) {

            completion(Result<T>(value: v))

        }

    }

    let fl = { (e: ErrorType) in

        Dispatch.async(queue: resultQueue) {

            completion(Result<T>(error: e))

        }

    }

    Dispatch.async(queue: runQueue) {

        do {

            try f(success: s, failure: fl)

        } catch {

            Dispatch.async(queue: resultQueue) {

                completion(Result<T>(error: error))
                
            }

        }
        
    }
    
}

extension Result {

    public static func strive<T>(@noescape f: Void throws -> T?) -> Result<T> {

        let lonesomeError: ErrorType?

        let value: T?

        do {

            value = try f()
            lonesomeError = nil

        } catch {

            value = nil
            lonesomeError = error

        }

        if let lonesomeError = lonesomeError {

            return Result<T>(error: lonesomeError)

        }
        
        if let value = value {
            
            return Result<T>(value: value)
            
        }
        
        return Result<T>(errors: [])
        
    }

    public static func strive<T>(@noescape f: (ErrorType -> T?) throws -> T?) -> Result<T> {

        var errors: [ErrorType] = []

        let value: T?

        do {

            value = try f { error in

                errors.append(error)
                return .None

            }

        } catch {

            value = nil
            errors.append(error)

        }

        if let value = value where errors.count == 0 {
            
            return Result<T>(value: value)
            
        }
        
        return Result<T>(errors: errors)
        
    }

    public static func strive<T>(@noescape f: (T -> Void) throws -> Void) -> Result<T> {

        var lonesomeError: ErrorType?
        var value: T?

        do {

            try f { v in

                value = v
                lonesomeError = nil

            }

        } catch {

            value = nil
            lonesomeError = error

        }

        if let value = value {

            return Result<T>(value: value)
            
        }

        if let error = lonesomeError {
        
            return Result<T>(error: error)

        }

        return Result<T>(errors: [])
        
    }

    public func failure(@noescape f: ErrorType -> Void) -> Result<T> {

        if let errors = errors {

            for error in errors {

                f(error)

            }

        }

        return self

    }

    public func failure<E: ErrorType>(type: E.Type, @noescape f: E -> Void) -> Result<T> {

        if let errors = errors {

            for error in errors {

                if let error = error as? E {

                    f(error)

                }

            }

        }

        return self

    }

    public func success(@noescape f: T -> Void) -> Result<T> {

        if let value = value {

            f(value)

        }

        return self

    }

    public func finally(@noescape finally: Void -> Void) -> Result<T> {

        finally()
        return self

    }

}

// MARK: - Functional

public func ??<T>(result: Result<T>, @autoclosure defaultValue: () -> T) -> T {

    switch result {

    case .Success(let value):
        return value

    case .Failure(_):
        return defaultValue()

    }

}

extension Result {

    public func map<U>(f: T -> U) -> Result<U> {

        switch self {

        case .Success(let value):
            return Result<U>(value: f(value))

        case .Failure(let errors):
            return Result<U>(errors: errors)

        }

    }

    public func flatMap<U>(flatMap: T -> Result<U>) -> Result<U> {
        
        switch self {
            
        case .Success(let value):
            return flatMap(value)
            
        case .Failure(let errors):
            return .Failure(errors)
            
        }
        
    }
    
}

// MARK: - Printable

extension Result : CustomStringConvertible {
    
    public var description: String {
        
        switch self {
            
        case .Success(let value):
            return "Success:\n\(value)"
            
        case .Failure(let errors):
            return "Failure:\n\(errors)"
            
        }
        
    }
    
}