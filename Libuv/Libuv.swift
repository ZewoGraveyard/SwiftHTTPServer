// Libuv.swift
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

extension Data {

    func withBufferRef(callback: BufferRef -> Void)  {

        var data = uv_buf_init(UnsafeMutablePointer<Int8>(bytes), UInt32(length))
        withUnsafePointer(&data, callback)

    }

}

func runTCPServer(port port: Int, handleClient: (client: TCPStream) -> Void) throws {
    
    let server = TCPStream()
    let address = SocketAddress(host: "0.0.0.0", port: port)

    server.bind(address)
    
    try server.listen(128) { status in
        
        guard status >= 0 else { return }
        
        let client = TCPStream()
        
        do {
            
            try server.accept(client)
            handleClient(client: client)
            
        } catch {
            
            client.closeAndFree()
            
        }
        
    }
    
}