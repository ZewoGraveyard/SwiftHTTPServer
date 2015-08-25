// Stream.swift
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

typealias StreamRef = UnsafeMutablePointer<uv_stream_t>
typealias WriteRef = UnsafeMutablePointer<uv_write_t>
typealias ReadBlock = ReadResult -> Void
typealias ListenBlock = (status: Int) -> Void

enum ReadResult {

    case Chunk(Data)
    case EOF
    case Error(UVError)
    
}

class StreamContext {

    var readBlock: ReadBlock?
    var listenBlock: ListenBlock?
    
}

class Stream {

    var stream: StreamRef

    init(_ stream: StreamRef) {

        self.stream = stream

    }

    func accept(client: Stream) throws {

        let result = uv_accept(stream, client.stream)

        if result < 0 {

            throw UVError.Error(code: result)

        }

    }

    func listen(backlog numConnections: Int, callback: uv_connection_cb) throws {

        let result = uv_listen(stream, Int32(numConnections), callback)

        if result < 0 {

            throw UVError.Error(code: result)

        }

    }

    func closeAndFree() {

        _context = nil

        uv_close(HandleRef(stream)) { handle in
            
            free(handle)
            
        }
        
    }
    
}

class WriteCompletionHandler {

    var completion: Void -> Void

    init(_ completion: Void -> Void) {

        self.completion = completion
        
    }
    
}

extension Stream {

    var context: StreamContext {

        if _context == nil {

            _context = StreamContext()

        }

        return _context!

    }

    var _context: StreamContext? {

        get {

            return fromVoidPointer(stream.memory.data)

        }

        set {

            let _: StreamContext? = releaseVoidPointer(stream.memory.data)
            stream.memory.data = retainedVoidPointer(newValue)

        }

    }

    func read(callback: ReadBlock) throws {

        context.readBlock = callback

        uv_read_start(stream, alloc_buffer) { serverStream, bytesRead, buf in

            defer { free_buffer(buf) }

            let stream = Stream(serverStream)

            let data: ReadResult

            if (bytesRead == Int(UV_EOF.rawValue)) {

                data = .EOF

            } else if (bytesRead < 0) {

                data = .Error(UVError.Error(code: Int32(bytesRead)))

            } else {

                data = .Chunk(Data(bytes: buf.memory.base, length: bytesRead))

            }

            stream.context.readBlock?(data)

        }

    }

    func listen(numConnections: Int, theCallback: ListenBlock) throws {

        context.listenBlock = theCallback

        try listen(backlog: numConnections) { serverStream, status in
            
            let stream = Stream(serverStream)
            stream.context.listenBlock?(status: Int(status))
            
        }
        
    }

    func writeAndFree(buffer: BufferRef, completion: Void -> Void) {

        let writeRef: WriteRef = WriteRef.alloc(1) // dealloced in the write callback

        writeRef.memory.data = UnsafeMutablePointer(Unmanaged.passRetained(WriteCompletionHandler(completion)).toOpaque())

        uv_write(writeRef, stream, buffer, 1) { request, _ in

            let completionHandler = Unmanaged<WriteCompletionHandler>.fromOpaque(COpaquePointer(request.memory.data)).takeRetainedValue().completion
            free(request.memory.bufs)
            free(request)
            completionHandler()
            
        }
        
    }
    
    func write(completion: Void -> Void)(buffer: BufferRef) {
        
        writeAndFree(buffer, completion: completion)
        
    }
    
}

extension Stream {

    func writeData(data: Data, completion: Void -> Void) {

        data.withBufferRef(write(completion))

    }

}

extension Stream {

    func bufferedRead(callback: Data -> Void) throws {

        try read { [unowned self] result in

            if case let .Chunk(data) = result {

                callback(data)

            } else {

                self.closeAndFree()

            }
            
        }
        
    }
    
}

