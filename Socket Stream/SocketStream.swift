// SocketStream.swift
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

final class SocketStream : Stream {

    let socket: Socket
    let channel: DispatchChannel

    init(socket: Socket) {

        self.socket = socket
        self.channel = Dispatch.createChannel(.Stream, fileDescriptor: socket.fileDescriptor) { error in

            if let error = error { Log.error(error) }

        }

        self.channel.setLowWater(1)

    }

    func readData(handler: Data -> Void) throws {

        Dispatch.read(channel) { (done: Bool, buffer: UnsafePointer<Void>, length: Int, error: ErrorType?) in

            let data = Data(bytes: buffer, length: length)
            handler(data)

        }

    }

    func writeData(data: Data, completion: (Void -> Void)? = nil) {

        let buffer = UnsafePointer<Void>(data.bytes)
        let length = data.length

        Dispatch.write(channel, dataBuffer: buffer, dataLength: length) { (done: Bool, buffer: UnsafePointer<Void>, length: Int, error: ErrorType?) in

            completion?()
            
        }
        
    }
    
    func close() {
        
        channel.close()
        
    }
    
}

func acceptClient(port port: TCPPort, handleClient: (client: Stream) -> Void) throws {

    let socket = try Socket(port: port, maxConnections: 128)

    Dispatch.async {

        while true {

            do {

                let clientSocket = try socket.acceptClient()
                let socketStream = SocketStream(socket: clientSocket)
                handleClient(client: socketStream)

            } catch {

                Log.error(error)
                
            }
            
        }
        
    }
    
}