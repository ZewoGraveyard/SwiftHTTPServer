// Socket.swift
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

typealias TCPPort = in_port_t
typealias SocketHandler = CInt

enum SocketError: ErrorType {

    case ConnectionClosed

}

struct Socket {

    private let socketHandler: SocketHandler

    private(set) var IP: String
    private(set) var port: TCPPort

    init(port: TCPPort, maxConnections: Int = 20) throws {

        self.socketHandler = try Socket.createSocketHandler()
        self.IP = "0.0.0.0"
        self.port = port

        try setReuseAddressOption()
        try setNoSigPipeOption()
        try bindTo(IP: self.IP, port: self.port)
        try listenWithMaxConnections(maxConnections)

    }

    init(IP: String, port: TCPPort) throws {

        self.socketHandler = try Socket.createSocketHandler()
        self.IP = "0.0.0.0"
        self.port = port

        try setReuseAddressOption()
        try setNoSigPipeOption()
        try connectTo(IP: self.IP, port: self.port)

    }

    func connectTo(IP IP: String, port: TCPPort) throws {

        let addresses = try addressesFromDNSHost(IP, port: port)

        var address = addresses.first!

        if connect(socketHandler, &address, socklen_t(sizeof(sockaddr_in))) == -1 {

            release()
            throw Error.lastSystemError(reason: "connect() failed")

        }

    }

    init(IP: String, port: TCPPort, socketHandler: SocketHandler) throws {

        if socketHandler == -1 {

            throw Error.Generic("Could not create Socket", "socketHandler is invalid")

        }

        self.IP = IP
        self.port = port
        self.socketHandler = socketHandler

    }

    func receiveByte() throws -> UInt8 {

        var buffer = [UInt8](count: 1, repeatedValue: 0)

        let result = recv(socketHandler, &buffer, Int(buffer.count), 0)

        if result == -1 {

            throw Error.lastSystemError(reason: "recv() failed")

        }

        if result == 0 {

            throw SocketError.ConnectionClosed

        }

        return UInt8(buffer[0])

    }

    func dataAvailable() throws -> Bool {

        var buffer = [UInt8](count: 1, repeatedValue: 0)

        let result = recv(socketHandler, &buffer, Int(buffer.count), MSG_PEEK)

        if result == -1 {

            throw Error.lastSystemError(reason: "recv() failed")
            
        } else if result == 0 {

            return false

        } else {

            return true

        }

    }

    func writeString(string: String) throws {

        try writeData(Data(string: string))

    }

    func writeData(data: Data) throws {

        var sent = 0
        let unsafePointer = UnsafePointer<UInt8>(data.bytes)

        while sent < data.length {

            let s = write(socketHandler, unsafePointer + sent, Int(data.length - sent))

            if s <= 0 {

                throw Error.lastSystemError(reason: "write() failed")

            }

            sent += s

        }

    }

    func acceptClient() throws -> Socket {

        var clientAddress = sockaddr(
            sa_len: 0,
            sa_family: 0,
            sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )

        var length: socklen_t = socklen_t(sizeof(sockaddr))

        let clientSocketHandler = accept(socketHandler, &clientAddress, &length)

        if clientSocketHandler == -1 {

            throw Error.lastSystemError(reason: "accept() failed")

        }

        var addressIn = sockaddr_in(
            sin_len: 0,
            sin_family: 0,
            sin_port: 0,
            sin_addr: in_addr(s_addr: 0),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )

        memcpy(&addressIn, &clientAddress, Int(sizeof(sockaddr_in)))

        var addressString = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)

        let result = inet_ntop(AF_INET, &addressIn.sin_addr.s_addr, &addressString, socklen_t(INET_ADDRSTRLEN))

        if result == nil {

            throw Error.lastSystemError(reason: "inet_ntop() failed")
            
        }

        guard let IP = String.fromCString(&addressString) else {

            throw Error.Generic("Could not get IP address from client", "CString not convertible to String")

        }

        let port = addressIn.sin_port

        let clientSocket = try Socket(IP: IP, port: port, socketHandler: clientSocketHandler)

        try clientSocket.setNoSigPipeOption()

        return clientSocket

    }

    private static func createSocketHandler() throws -> SocketHandler {

        let socketHandler = socket(AF_INET, SOCK_STREAM, 0)

        if socketHandler == -1 {

            throw Error.lastSystemError(reason: "socket() failed")

        }

        return socketHandler

    }

    private func setReuseAddressOption() throws {

        var reuseAddressValue: Int32 = 1

        if setsockopt(socketHandler, SOL_SOCKET, SO_REUSEADDR, &reuseAddressValue, socklen_t(sizeof(Int32))) == -1  {

            release()
            throw Error.lastSystemError(reason: "reuseAddress() failed")
            
        }

    }

    private func setNoSigPipeOption() throws {

        var noSigPipeValue: Int32 = 1

        if setsockopt(socketHandler, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipeValue, socklen_t(sizeof(Int32))) == -1  {

            release()
            throw Error.lastSystemError(reason: "noSigPipe() failed")

        }

    }

    private func bindTo(IP IP: String, port: TCPPort) throws {

        var addressIn = sockaddr_in(
            sin_len: __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port: port_htons(port),
            sin_addr: in_addr(s_addr: inet_addr(IP)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )

        var address = sockaddr(
            sa_len: 0,
            sa_family: 0,
            sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )
        
        memcpy(&address, &addressIn, Int(sizeof(sockaddr_in)))
        
        if bind(socketHandler, &address, socklen_t(sizeof(sockaddr_in))) == -1 {
            
            release()
            throw Error.lastSystemError(reason: "bind() failed")
            
        }
        
    }
    
    private func port_htons(port: TCPPort) -> TCPPort {
        
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
        
    }

    private func addressesFromDNSHost(host: String, port: TCPPort) throws -> [sockaddr] {

        var addresses: [sockaddr] = []

        var hints = addrinfo(
            ai_flags: 0,
            ai_family: AF_INET,
            ai_socktype: SOCK_STREAM,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )

        var results = UnsafeMutablePointer<addrinfo>()

        let portString = "\(port)"

        if getaddrinfo(host, portString, &hints, &results) == -1 {

            release()
            throw Error.lastSystemError(reason: "getaddrinfo() failed")

        }

        for var resultPointer = results; resultPointer != nil; resultPointer = resultPointer.memory.ai_next {

            let result = resultPointer.memory
            let address = result.ai_addr.memory
            addresses.append(address)
            
        }
        
        freeaddrinfo(results)

        if addresses.count == 0 {

            release()
            throw Error.Generic("DNS solve error", "No addresses returned from DNS query")
            
        }

        return addresses

    }

    private func listenWithMaxConnections(maxConnections: Int) throws {

        if listen(socketHandler, Int32(maxConnections)) == -1 {

            release()
            throw Error.lastSystemError(reason: "listen() failed")
            
        }

    }
    
    func release() {
        
        shutdown(socketHandler, SHUT_RDWR)
        close(socketHandler)
        
    }
    
}
