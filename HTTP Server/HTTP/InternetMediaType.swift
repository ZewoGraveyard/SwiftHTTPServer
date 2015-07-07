// InternetMediaType.swift
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

enum InternetMediaType {

    case ApplicationJSON
    case ApplicationXWWWFormURLEncoded
    case MultipartFormData(boundary: String)
    case TextHTML
    case TextPlain

    case Unrecognized(mediaType: String)

    init(string: String) {

        let (mediaType, parameters) = InternetMediaType.getMediaTypeParameters(string)

        switch mediaType {

        case "application/json":
            self = ApplicationJSON

        case "application/x-www-form-urlencoded":
            self = ApplicationXWWWFormURLEncoded

        case "multipart/form-data":
            if let boundary = parameters["boundary"]  {

                self = MultipartFormData(boundary: boundary)

            } else {

                Log.warning("Failed to create multipart/form-data InternetMediaType: boundary parameter missing")
                self = Unrecognized(mediaType: mediaType)

            }

        case "text/html":
            self = TextHTML

        case "text/plain":
            self = TextPlain

        default:
            Log.warning("Unrecognized InternetMediaType: \(mediaType)")
            self = Unrecognized(mediaType: mediaType)
            
        }
        
    }

    private static func getMediaTypeParameters(mediaType: String) -> (mediaType: String, parameters: [String: String]) {

        let mediaTypeTokens = mediaType.splitBy(";")
        let mediaType = mediaTypeTokens.first!
        var parameters: [String: String] = [:]

        if mediaTypeTokens.count == 2 {

            let parametersTokens = mediaTypeTokens[1].trim().splitBy(" ")

            for parametersToken in parametersTokens {

                let parameterTokens = parametersToken.splitBy("=")

                if parameterTokens.count == 2 {

                    let key = parameterTokens[0]
                    let value = parameterTokens[1]
                    parameters[key] = value

                }


            }

        }

        return (mediaType: mediaType, parameters: parameters)

    }

}

extension InternetMediaType: CustomStringConvertible {

    var description: String {

        switch self {

        case .ApplicationJSON:                 return "application/json"
        case .ApplicationXWWWFormURLEncoded:   return "application/x-www-form-urlencoded"
        case .MultipartFormData(let boundary): return "multipart/form-data; boundary=\(boundary)"
        case .TextHTML:                        return "text/html"
        case .TextPlain:                       return "text/plain"
        case .Unrecognized(let mediaType):     return mediaType

        }

    }

}
