// RunLoop.swift
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

typealias LoopRef = UnsafeMutablePointer<uv_loop_t>

class UVRunLoop : RunLoop {

    enum RunMode {

        case Default
        case Once
        case NoWait

        var rawValue: uv_run_mode {

            switch self {

            case Default: return UV_RUN_DEFAULT
            case Once:    return UV_RUN_ONCE
            case NoWait:  return UV_RUN_NOWAIT

            }

        }
        
    }

    let loop: LoopRef

    init(loop: LoopRef = UnsafeMutablePointer.alloc(1)) {

        self.loop = loop
        uv_loop_init(loop)

    }

    deinit {

        close()

    }

    func run() {

        uv_run(loop, RunMode.Default.rawValue)

    }

    func close() {

        uv_loop_close(loop)
        loop.dealloc(1)

    }
    
    static let defaultLoop = UVRunLoop(loop: uv_default_loop())
    
}
