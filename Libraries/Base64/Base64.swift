func base64Decode(encoded: String) -> String {

    let ascii: [UInt8] = [

        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
        64, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
        64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        
    ]

    var decoded: String = ""

    func appendCharacter(character: UInt8) {

        decoded.append(UnicodeScalar(character))

    }

    var unreadBytes = 0

    for character in encoded.utf8 {

        if ascii[Int(character)] > 63 { break }
        unreadBytes++

    }

    let encodedBytes = encoded.utf8.map { Int($0) }
    var index = 0

    while unreadBytes > 4 {

        appendCharacter(ascii[encodedBytes[index + 0]] << 2 | ascii[encodedBytes[index + 1]] >> 4)
        appendCharacter(ascii[encodedBytes[index + 1]] << 4 | ascii[encodedBytes[index + 2]] >> 2)
        appendCharacter(ascii[encodedBytes[index + 2]] << 6 | ascii[encodedBytes[index + 3]])

        index += 4
        unreadBytes -= 4

    }

    if unreadBytes > 1 {

        appendCharacter(ascii[encodedBytes[index + 0]] << 2 | ascii[encodedBytes[index + 1]] >> 4)

    }

    if unreadBytes > 2 {

        appendCharacter(ascii[encodedBytes[index + 1]] << 4 | ascii[encodedBytes[index + 2]] >> 2)
        
    }

    if unreadBytes > 3 {

        appendCharacter(ascii[encodedBytes[index + 2]] << 6 | ascii[encodedBytes[index + 3]])
        
    }

    return decoded

}

func base64Encode(decoded: String) -> String {

    let base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    var encoded: String = ""

    func appendCharacterFromBase(character: Int) {

        encoded.append(base64[base64.startIndex.advancedBy(character)])

    }

    func appendCharacter(character: Character) {

        encoded.append(character)
        
    }

    let decodedBytes = decoded.utf8.map { Int($0) }

    var i = 0

    while i < decodedBytes.count - 2 {

        appendCharacterFromBase(( decodedBytes[i] >> 2) & 0x3F)
        appendCharacterFromBase(((decodedBytes[i]       & 0x3) << 4) | ((decodedBytes[i + 1] & 0xF0) >> 4))
        appendCharacterFromBase(((decodedBytes[i + 1]   & 0xF) << 2) | ((decodedBytes[i + 2] & 0xC0) >> 6))
        appendCharacterFromBase(  decodedBytes[i + 2]   & 0x3F)

        i += 3

    }

    if i < decodedBytes.count {

        appendCharacterFromBase((decodedBytes[i] >> 2) & 0x3F)

        if i == decodedBytes.count - 1 {

            appendCharacterFromBase(((decodedBytes[i] & 0x3) << 4))
            appendCharacter("=")

        } else {

            appendCharacterFromBase(((decodedBytes[i]     & 0x3) << 4) | ((decodedBytes[i + 1] & 0xF0) >> 4))
            appendCharacterFromBase(((decodedBytes[i + 1] & 0xF) << 2))

        }

        appendCharacter("=")

    }

    return encoded

}