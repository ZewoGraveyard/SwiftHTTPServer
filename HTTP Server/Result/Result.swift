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

// MARK: - Try, Convert, Catch, Value, Finally

public func strive<T>(@noescape throwError: (ErrorType -> T?) -> T?) -> Result<T> {

    return Result<T>.strive(throwError)

}

extension Result {

    public static func strive<T>(@noescape tryResult: (ErrorType -> T?) -> T?) -> Result<T> {

        var errors: [ErrorType] = []

        let value = tryResult { error in

            errors.append(error)
            return .None

        }

        if errors.count > 0 {

            return .Failure(errors)

        }

        if let value = value {

            return .Success(value)

        }

        return .Failure(errors)

    }

    public func failure(@noescape capture: ErrorType -> Void) -> Result<T> {

        if let errors = errors {

            for error in errors {

                capture(error)

            }

        }

        return self

    }

    public func failure<E: ErrorType>(type: E.Type, @noescape catchResult: E -> Void) -> Result<T> {

        if let errors = errors {

            for error in errors {

                if let error = error as? E {

                    catchResult(error)

                }

            }

        }

        return self

    }

    public func success(@noescape v: T -> Void) -> Result<T> {

        switch self {

        case .Success(let value):

            let x = value
            v(x)

        case .Failure(_):
            break

        }

        return self

    }

    public func finally(@noescape finally: Void -> Void) -> Result<T> {

        finally()
        return self

    }

}

// MARK: - Deliver

public func deliver<T>(handler: T -> Void, runQueue: Queue = defaultQueue, resultQueue: Queue = mainQueue, run: Void -> T) {

    Dispatch.async(queue: runQueue) {

        let result = run()

        Dispatch.async(queue: resultQueue) {

            handler(result)

        }

    }

}

public func strive<T>(result: Result<T> -> Void, runQueue: Queue = defaultQueue, resultQueue: Queue = mainQueue, run: (ErrorType -> T?) -> T?) {

    deliver(result, runQueue: runQueue, resultQueue: resultQueue) {

        strive(run)

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

// MARK: - Custom String Convertible

extension Result: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
            
        case .Success(let value):
            return "Success: \(value)"
            
        case .Failure(let errors):
            return "Failure: \(errors)"
            
        }
        
    }
    
}
