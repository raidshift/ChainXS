import Foundation

public struct Bech32CashAddr {
    static let base32Alphabets = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

    /// Encodes the data to Bech32 encoded string
    ///
    /// Creates checksum bytes from the prefix and the payload, and then puts the
    /// checksum bytes to the original data. Then, encode the combined data to
    /// Base32 string. At last, returns the combined string of prefix, separator
    /// and the encoded base32 text.
    /// ```
    /// let address = Base58Check.encode(payload: [versionByte] + pubkeyHash,
    ///                                  prefix: "bitcoincash")
    /// ```
    /// - Parameters:
    ///   - payload: The data to encode
    ///   - prefix: The prefix of the encoded text. It is also used to create checksum.
    ///   - separator: separator that separates prefix and Base32 encoded text
    public static func encode(payload: Data, prefix: String, separator: String = ":") -> String {
        // let payloadUint5 = convertTo5bit(data: payload, pad: true)
        let payloadUint5 = try! payload.convertBits(from: 8, to: 5, pad: true)
        let checksumUint5: Data = createChecksum(prefix: prefix, payload: payloadUint5) // Data of [UInt5]
        let combined: Data = payloadUint5 + checksumUint5 // Data of [UInt5]
        var base32 = ""
        for b in combined {
            let index = String.Index(utf16Offset: Int(b), in: base32Alphabets)
            base32 += String(base32Alphabets[index])
        }

        return prefix + separator + base32
    }

    static func expand(_ prefix: String) -> Data {
        var ret = Data()
        let buf: [UInt8] = Array(prefix.utf8)
        for b in buf {
            // ret += b & 0x1F
            ret.append(b & 0x1F)
        }
        ret += Data(repeating: 0, count: 1)
        // ret.append(0x00)
        return ret
    }

    static func createChecksum(prefix: String, payload: Data) -> Data {
        let enc: Data = expand(prefix) + payload + Data(repeating: 0, count: 8)
        let mod: UInt64 = PolyMod(enc)
        var ret = Data()
        for i in 0 ..< 8 {
            // ret += UInt8((mod >> (5 * (7 - i))) & 0x1F)
            ret.append(UInt8((mod >> (5 * (7 - i))) & 0x1F))
        }
        return ret
    }

    static func PolyMod(_ data: Data) -> UInt64 {
        var c: UInt64 = 1
        for d in data {
            let c0 = UInt8(c >> 35)
            c = ((c & 0x07_FFFF_FFFF) << 5) ^ UInt64(d)
            if c0 & 0x01 != 0 { c ^= 0x98_F2BC_8E61 }
            if c0 & 0x02 != 0 { c ^= 0x79_B76D_99E2 }
            if c0 & 0x04 != 0 { c ^= 0xF3_3E5F_B3C4 }
            if c0 & 0x08 != 0 { c ^= 0xAE_2EAB_E2A8 }
            if c0 & 0x10 != 0 { c ^= 0x1E_4F43_E470 }
        }
        return c ^ 1
    }
}
