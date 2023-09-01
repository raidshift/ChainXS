import CommonCrypto
import Foundation

let SALT_LEN = 8
let IV_LEN = 16
let KEY_LEN = 32

let COMMENT = "############  salt:iv:aes_256_cbc_pbkdf2_sha512_250000_base64(bin) #############"

enum PBKDF2_ERR: Error {
    case SALT_LEN
    case PASSWORD_LEN
    case CORE
}

extension PBKDF2_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .SALT_LEN:
            return NSLocalizedString("Unable to process password", comment: "Unable to process password")
        case .PASSWORD_LEN:
            return NSLocalizedString("Invalid password", comment: "Invalid password")
        case .CORE:
            return NSLocalizedString("Unable to process password", comment: "Unable to process password")
        }
    }
}

enum ENCRYPT_ERR: Error {
    case KEY_LEN
    case IV_LEN
    case CORE
}

extension ENCRYPT_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .KEY_LEN:
            return NSLocalizedString("Unable to encrypt data", comment: "Unable to encrypt data")
        case .IV_LEN:
            return NSLocalizedString("Unable to encrypt data", comment: "Unable to encrypt data")
        case .CORE:
            return NSLocalizedString("Unable to encrypt data", comment: "Unable to encrypt data")
        }
    }
}

enum DECRYPT_ERR: Error {
    case KEY_LEN
    case IV_LEN
    case CORE
    case FORMAT
    case WRONG_PASSWORD
}

extension DECRYPT_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .KEY_LEN:
            return NSLocalizedString("Unable to decrypt data", comment: "Unable to decrypt data")
        case .IV_LEN:
            return NSLocalizedString("Unable to decrypt data", comment: "Unable to decrypt data")
        case .CORE:
            return NSLocalizedString("Unable to decrypt data", comment: "Unable to decrypt data")
        case .FORMAT:
            return NSLocalizedString("Unable to decrypt data", comment: "Unable to decrypt data")
        case .WRONG_PASSWORD:
            return NSLocalizedString("Wrong password", comment: "Wrong password")
        }
    }
}

func pbkdf2(password: String, salt: [UInt8]) throws -> [UInt8] {
    if salt.count != SALT_LEN { throw PBKDF2_ERR.SALT_LEN }
    if password.count < 1 || password.count > 100 { throw PBKDF2_ERR.PASSWORD_LEN }

    let passwordData = password.data(using: .utf8)!
    var derivedKeyData = [UInt8](repeating: 0, count: kCCKeySizeAES256)

    if CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordData.count, salt, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), UInt32(250_000), &derivedKeyData, derivedKeyData.count) != kCCSuccess { throw PBKDF2_ERR.CORE }

    return derivedKeyData
}

func encrypt(key: [UInt8], iv: [UInt8], plaintext: [UInt8]) throws -> [UInt8] {
    if key.count != KEY_LEN { throw ENCRYPT_ERR.KEY_LEN }
    if iv.count != IV_LEN { throw ENCRYPT_ERR.IV_LEN }

    var cyphertext = [UInt8](repeating: 0, count: plaintext.count + IV_LEN)
    var len = 0

    if CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), key, kCCKeySizeAES256, iv, plaintext, plaintext.count, &cyphertext, cyphertext.count, &len) != kCCSuccess { throw ENCRYPT_ERR.CORE }

    return Array(cyphertext[0 ..< len])
}

func decrypt(key: [UInt8], iv: [UInt8], cyphertext: [UInt8]) throws -> [UInt8] {
    if key.count != KEY_LEN { throw DECRYPT_ERR.KEY_LEN }
    if iv.count != IV_LEN { throw DECRYPT_ERR.IV_LEN }

    var plaintext = [UInt8](repeating: 0, count: cyphertext.count)
    var len = 0

    if CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), key, kCCKeySizeAES256, iv, cyphertext, cyphertext.count, &plaintext, plaintext.count, &len) != kCCSuccess { throw DECRYPT_ERR.CORE }

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
    if params.count != 3 { throw DECRYPT_ERR.FORMAT }

    return try (params[0].hexaToBytes, params[1].hexaToBytes, [UInt8]((Data(base64Encoded: params[2]) ?? { throw DECRYPT_ERR.FORMAT }())))
}
