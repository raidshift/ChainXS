import CommonCrypto
import Foundation

let SALT_LEN = 8
let IV_LEN = 16
let KEY_LEN = 32

let COMMENT = "############  salt:iv:aes_256_cbc_pbkdf2_sha512_250000_base64(bin) #############"

enum PBKDF2_ERR: Error {
    case SALT_LEN
    case DERIVATION
}

enum ENCDEC_ERR: Error {
    case KEY_LEN
    case IV_LEN
    case ENCRYPT
    case DECRYPT
    case FORMAT_CYPHERTEXT
}

func pbkdf2(password: String, salt: [UInt8]) throws -> [UInt8] {
    if salt.count != SALT_LEN { throw PBKDF2_ERR.SALT_LEN }

    let passwordData = password.data(using: .utf8)!
    var derivedKeyData = [UInt8](repeating: 0, count: kCCKeySizeAES256)

    if CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordData.count, salt, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), UInt32(250_000), &derivedKeyData, derivedKeyData.count) != kCCSuccess { throw PBKDF2_ERR.DERIVATION }

    return derivedKeyData
}

func encrypt(key: [UInt8], iv: [UInt8], plaintext: [UInt8]) throws -> [UInt8] {
    if key.count != KEY_LEN { throw ENCDEC_ERR.KEY_LEN }
    if iv.count != IV_LEN { throw ENCDEC_ERR.IV_LEN }

    var cyphertext = [UInt8](repeating: 0, count: plaintext.count + IV_LEN)
    var len = 0

    if CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), key, kCCKeySizeAES256, iv, plaintext, plaintext.count, &cyphertext, cyphertext.count, &len) != kCCSuccess { throw ENCDEC_ERR.ENCRYPT }

    return Array(cyphertext[0 ..< len])
}

func decrypt(key: [UInt8], iv: [UInt8], cyphertext: [UInt8]) throws -> [UInt8] {
    if key.count != KEY_LEN { throw ENCDEC_ERR.KEY_LEN }
    if iv.count != IV_LEN { throw ENCDEC_ERR.IV_LEN }

    var plaintext = [UInt8](repeating: 0, count: cyphertext.count)
    var len = 0

    if CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), key, kCCKeySizeAES256, iv, cyphertext, cyphertext.count, &plaintext, plaintext.count, &len) != kCCSuccess { throw ENCDEC_ERR.DECRYPT }

    return Array(plaintext[0 ..< len])
}

func bytes2Hex(bytes: [UInt8]) -> String {
    var string = ""
    for byte in bytes {
        string = string + String(format: "%02x", byte)
    }
    return string
}

func bundleCypherParams(salt: [UInt8], iv: [UInt8], cyphertext: [UInt8]) throws -> String {
    return "\(COMMENT)\n\n" + "\(bytes2Hex(bytes: salt)):\(bytes2Hex(bytes: iv)):\(Data(cyphertext).base64EncodedString())".split(len: 80)
}

func unbundleCypherParams(bundle: String) throws -> (salt: [UInt8], iv: [UInt8], cyphertext: [UInt8]) {
    let lines = bundle.components(separatedBy: "\n")
    var cypherBundle = ""

    lines.forEach {
        let line = $0.trimmingCharacters(in: .whitespaces)
        if line != "", !line.hasPrefix("#") {
            cypherBundle += line
        }
    }

    let params = (cypherBundle.filter { !$0.isWhitespace }).components(separatedBy: ":")
    
    return try (params[0].hexaToBytes , params[1].hexaToBytes, [UInt8]((Data(base64Encoded: params[2]) ?? { throw ENCDEC_ERR.FORMAT_CYPHERTEXT }())))
}