// main.swift
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

let address: String = "localhost"
let port: TCPPort = 9090

let request =  HTTPRequest(
    method: .GET,
    uri: URI("/over/there/index.dtb?type=animal&name=narwhal#nose")!,
    headers: [
        "host": "localhost",
        "accept": "*/*",
        "user-agent": "HTTP Client",
        "csp": "active",
        "accept-encoding": "gzip, deflate, sdch",
        "accept-language": "pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4,en-GB;q=0.2,de;q=0.2",
        "cache-control": "no-cache",
        "connection": "keep-alive"
    ]
)

Log.info(request)

HTTPClient.sendRequest(request, address: address, port: port) { response in

    Log.info(response)

}

Dispatch.main()