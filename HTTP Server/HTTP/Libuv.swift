func printErr(errorCode: Int) {

    let strError = uv_strerror(Int32(errorCode))
    let str = String.fromCString(strError)!
    print("Error \(errorCode): \(str)")

}

typealias LoopRef = UnsafeMutablePointer<uv_loop_t>
typealias HandleRef = UnsafeMutablePointer<uv_handle_t>
typealias StreamRef = UnsafeMutablePointer<uv_stream_t>
typealias WriteRef = UnsafeMutablePointer<uv_write_t>
typealias BufferRef = UnsafePointer<uv_buf_t>

class Loop {

    let loop: UnsafeMutablePointer<uv_loop_t>

    init(loop: UnsafeMutablePointer<uv_loop_t> = UnsafeMutablePointer.alloc(1)) {

        self.loop = loop
        uv_loop_init(loop)

    }

    func run(mode: uv_run_mode) {

        uv_run(loop, mode)

    }

    deinit {

        uv_loop_close(loop)
        loop.dealloc(1)

    }

    static var defaultLoop = Loop(loop: uv_default_loop())

}

enum UVError: ErrorType {

    case Error(code: Int32)

}

extension UVError : CustomStringConvertible {

    var description: String {

        switch self {

        case .Error(let code):
            return String.fromCString(uv_err_name(code)) ?? "Unknown error"

        }

    }

}

class Address {

    var addr = UnsafeMutablePointer<sockaddr_in>.alloc(1)

    var address: UnsafePointer<sockaddr> {

        return UnsafePointer(addr)

    }

    init(host: String, port: Int) {

        uv_ip4_addr(host, Int32(port), addr)

    }

    deinit {

        addr.dealloc(1)

    }

}

class Stream {

    var stream: StreamRef

    init(_ stream: StreamRef) {

        self.stream = stream

    }

    func accept(client: Stream) throws -> () {

        let result = uv_accept(stream, client.stream)
        if result < 0 { throw UVError.Error(code: result) }

    }

    func listen(backlog numConnections: Int, callback: uv_connection_cb) throws -> () {

        let result = uv_listen(stream, Int32(numConnections), callback)
        if result < 0 { throw UVError.Error(code: result) }

    }

    func closeAndFree() {

        _context = nil

        uv_close(UnsafeMutablePointer(stream)) { handle in

            free(handle)

        }

    }

}

final class Pack<A> {

    let unpack: A
    init(_ value: A) { unpack = value }

}

func retainedVoidPointer<A>(x: A?) -> UnsafeMutablePointer<Void> {

    guard let value = x else { return UnsafeMutablePointer() }
    let unmanaged = Unmanaged.passRetained(Pack(value))
    return UnsafeMutablePointer(unmanaged.toOpaque())

}

func fromVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {

    guard x != nil else { return nil }
    return Unmanaged<Pack<A>>.fromOpaque(COpaquePointer(x)).takeUnretainedValue().unpack

}

func releaseVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {

    guard x != nil else { return nil }
    return Unmanaged<Pack<A>>.fromOpaque(COpaquePointer(x)).takeRetainedValue().unpack

}

typealias ReadBlock = ReadResult -> Void
typealias ListenBlock = (status: Int) -> Void

class StreamContext {

    var readBlock: ReadBlock?
    var listenBlock: ListenBlock?

}

private func alloc_buffer(_: UnsafeMutablePointer<uv_handle_t>, suggestedSize: Int, buffer: UnsafeMutablePointer<uv_buf_t>) -> () {

    buffer.memory = uv_buf_init(UnsafeMutablePointer.alloc(suggestedSize), UInt32(suggestedSize))

}

private func free_buffer(buffer: UnsafePointer<uv_buf_t>) {

    free(buffer.memory.base)

}

enum ReadResult {

    case Chunk(Data)
    case EOF
    case Error(UVError)

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

    func listen(numConnections: Int, theCallback: ListenBlock) throws -> () {

        context.listenBlock = theCallback

        try listen(backlog: numConnections, callback: { serverStream, status in

            let stream = Stream(serverStream)
            stream.context.listenBlock?(status: Int(status))

        })

    }

    func write(completion: () -> ())(buffer: BufferRef) {

        Write().writeAndFree(self, buffer: buffer, completion: completion)

    }

}

class WriteCompletionHandler {

    var completion: () -> ()

    init(_ c: () -> ()) {

        completion = c

    }

}

class Write {

    var writeRef: WriteRef = WriteRef.alloc(1) // dealloced in the write callback

    func writeAndFree(stream: Stream, buffer: BufferRef, completion: () -> ()) {

        assert(writeRef != nil)

        writeRef.memory.data = UnsafeMutablePointer(Unmanaged.passRetained(WriteCompletionHandler(completion)).toOpaque())

        uv_write(writeRef, stream.stream, buffer, 1, { x, _ in

            let completionHandler = Unmanaged<WriteCompletionHandler>.fromOpaque(COpaquePointer(x.memory.data)).takeRetainedValue().completion
            free(x.memory.bufs)
            free(x)
            completionHandler()

        })

    }

}

class TCP: Stream {

    let socket = UnsafeMutablePointer<uv_tcp_t>.alloc(1)

    init(loop: Loop = Loop.defaultLoop) {

        super.init(UnsafeMutablePointer(self.socket))
        uv_tcp_init(loop.loop, socket)

    }

    func bind(address: Address) {

        uv_tcp_bind(socket, address.address, 0)

    }

}

extension Data {

    func withBufferRef(callback: BufferRef -> ()) -> () {

        let bytes = UnsafeMutablePointer<Int8>.alloc(length)
        memcpy(bytes, self.bytes, length)
        var data = uv_buf_init(bytes, UInt32(length))
        withUnsafePointer(&data, callback)

    }

}

extension Stream {

    func writeData(data: Data, completion: () -> ()) {

        data.withBufferRef(write(completion))

    }

}

extension Stream {

    func bufferedRead(callback: Data -> ()) throws -> () {

        //var mutableData = Data()

        try read { [unowned self] result in

            if case let .Chunk(data) = result {

                //mutableData = mutableData + data
                callback(data)
                
            } else if case .EOF = result {
                
                //callback(mutableData)
                
            } else {
                
                self.closeAndFree()
                
            }
            
        }
        
    }
    
}

func runTCPServer(port port: Int, handleClient: (client: TCP) -> Void) throws {
    
    let server = TCP()
    let addr = Address(host: "0.0.0.0", port: port)
    server.bind(addr)
    
    try server.listen(Int(SOMAXCONN)) { status in
        
        guard status >= 0 else { return }
        
        let client = TCP()
        
        do {
            
            try server.accept(client)
            handleClient(client: client)
            
        } catch {
            
            client.closeAndFree()
            
        }
        
    }
    
    Loop.defaultLoop.run(UV_RUN_DEFAULT)
    
}