//
//  DataExt.swift
//
//  Created by Laurenz Zielinski
//

import Foundation

extension Data {
    public init(randomOfLength count: Int) {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        assert(status == 0)
        self.init(bytes)
    }

    var hexString: String {
        return map { byte in String(format: "%02x", byte) }.joined()
    }

    var base58CheckString: String {
        var bytes = [UInt8](self)
        var zerosCount = 0
        var length = 0

        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }

        bytes.removeFirst(zerosCount)

        let size = bytes.count * 138 / 100 + 1

        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0

            for j in 0 ... base58.count - 1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }

            assert(carry == 0)

            length = i
        }

        // skip leading zeros
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)

        while zerosCount > 0 {
            str = "\(str)1"
            zerosCount -= 1
        }

        for b in base58 {
            str = "\(str)\(String.base58Alphabet[String.Index(utf16Offset: Int(b), in: String.base58Alphabet)])"
        }

        return str
    }

    var left: Data {
        return subdata(in: 0 ..< count / 2)
    }

    var right: Data {
        return subdata(in: count / 2 ..< count)
    }
}
