// HTTPResponse+Template.swift
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

extension HTTPResponse {

    init(
        status: HTTPStatus = .OK,
        version: HTTPVersion = .HTTP_1_1,
        headers: [String: String] = [:],
        templatePath: String,
        templateData: MustacheBoxable) throws {

            guard let templateFile = File(path: templatePath) else {

                throw Error.Generic("Template Response Body", "Could not find template at path: \(templatePath)")

            }

            guard let templateString = String(data: templateFile.data) else {

                throw Error.Generic("Template Response Body", "Template at path: \(templatePath); is not UTF-8 encoded")

            }

            let template = try Template(string: templateString)
            let rendering = try template.render(Box(templateData))

            self.init(
                status: status,
                version: version,
                headers: headers + ["content-type": "text/html"],
                body: Data(string: rendering)
            )
            
    }
    
}