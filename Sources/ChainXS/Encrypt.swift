import CommonCrypto
import Foundation

let PBKDF2_ITER = 1_000_000

enum ENCRYPT_ERR: Error {
    case FORMAT
    case PASSWORD
    case CORE_KDF
    case CORE_AES
}

let ENCRYPT_ERR_TEXT_FORMAT = "Input data is too short"
let ENCRYPT_ERR_TEXT_PASSWORD = "Incorrect password"
let ENCRYPT_ERR_CORE_KDF = "Invoking key derivation failed"
let ENCRYPT_ERR_CORE_AES = "Invoking encryption/decryption failed"

extension ENCRYPT_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FORMAT:
            return NSLocalizedString(ENCRYPT_ERR_TEXT_FORMAT, comment: ENCRYPT_ERR_TEXT_FORMAT)
        case .PASSWORD:
            return NSLocalizedString(ENCRYPT_ERR_TEXT_PASSWORD, comment: ENCRYPT_ERR_TEXT_PASSWORD)
        case .CORE_KDF:
            return NSLocalizedString(ENCRYPT_ERR_CORE_KDF, comment: ENCRYPT_ERR_CORE_KDF)
        case .CORE_AES:
            return NSLocalizedString(ENCRYPT_ERR_CORE_AES, comment: ENCRYPT_ERR_CORE_AES)
        }
    }
}

struct Encrypt {
    private var buffer: Data
    var cyphertext = Data()

    init(password: inout Data, plaintext: inout Data) throws {
        var plaintext = Data(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH)) + plaintext
        var key = Data(repeating: 0, count: kCCKeySizeAES256)

        plaintext.withUnsafeMutableBytes { _ = CC_SHA256($0.baseAddress! + Int(CC_SHA256_DIGEST_LENGTH), CC_LONG($0.count - Int(CC_SHA256_DIGEST_LENGTH)), $0.baseAddress!) }
        buffer = try Data(randomOfLength: kCCBlockSizeAES128) + Data(repeating: 0, count: plaintext.count + kCCBlockSizeAES128)

        try key.withUnsafeMutableBytes { keyBytes in
            try buffer.withUnsafeBytes { saltBytes in
                try password.withUnsafeBytes { passwordBytes in
                    if CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes.baseAddress!, password.count, saltBytes.baseAddress!, kCCBlockSizeAES128, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), UInt32(PBKDF2_ITER), keyBytes.baseAddress!, kCCKeySizeAES256) != kCCSuccess { throw ENCRYPT_ERR.CORE_KDF }
                }
            }
        }

        let toBytesMaxLen = buffer.count - kCCBlockSizeAES128
        var toBytesLen = 0

        try buffer.withUnsafeMutableBytes { toBytes in
            try key.withUnsafeBytes { keyBytes in
                try plaintext.withUnsafeBytes { fromBytes in
                    if CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyBytes.baseAddress!, kCCKeySizeAES256, toBytes.baseAddress!, fromBytes.baseAddress!, fromBytes.count, toBytes.baseAddress! + kCCBlockSizeAES128, toBytesMaxLen, &toBytesLen) != kCCSuccess { throw ENCRYPT_ERR.CORE_AES }
                }
            }
        }
        buffer.withUnsafeMutableBytes { ptr in
            cyphertext = Data(bytesNoCopy: ptr.baseAddress!, count: toBytesLen + kCCBlockSizeAES128, deallocator: .none)
        }
    }
}

struct Decrypt {
    private var buffer: Data
    var plaintext = Data()

    init(password: inout Data, cyphertext: inout Data) throws {
        if cyphertext.count < Int(CC_SHA256_DIGEST_LENGTH) + 2 * kCCBlockSizeAES128 { throw ENCRYPT_ERR.FORMAT }

        var key = Data(repeating: 0, count: kCCKeySizeAES256)
        buffer = Data(repeating: 0, count: cyphertext.count - kCCBlockSizeAES128)

        try key.withUnsafeMutableBytes { keyBytes in
            try cyphertext.withUnsafeBytes { saltBytes in
                try password.withUnsafeBytes { passwordBytes in
                    if CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes.baseAddress!, passwordBytes.count, saltBytes.baseAddress!, kCCBlockSizeAES128, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), UInt32(PBKDF2_ITER), keyBytes.baseAddress!, kCCKeySizeAES256) != kCCSuccess { throw ENCRYPT_ERR.CORE_KDF }
                }
            }
        }

        var toBytesLen = 0

        try buffer.withUnsafeMutableBytes { toBytes in
            try key.withUnsafeBytes { keyBytes in
                try cyphertext.withUnsafeBytes { fromBytes in
                    if CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyBytes.baseAddress!, kCCKeySizeAES256, fromBytes.baseAddress!, fromBytes.baseAddress! + kCCBlockSizeAES128, fromBytes.count - kCCBlockSizeAES128, toBytes.baseAddress!, toBytes.count, &toBytesLen) != kCCSuccess { throw ENCRYPT_ERR.CORE_AES }
                }
            }
        }

        var hash = Data()
        var hash2 = Data(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        buffer.withUnsafeMutableBytes { ptr in
            hash = Data(bytesNoCopy: ptr.baseAddress!, count: Int(CC_SHA256_DIGEST_LENGTH), deallocator: .none)
            plaintext = Data(bytesNoCopy: ptr.baseAddress! + Int(CC_SHA256_DIGEST_LENGTH), count: toBytesLen - Int(CC_SHA256_DIGEST_LENGTH), deallocator: .none)
        }

        plaintext.withUnsafeBytes { plainBytes in
            hash2.withUnsafeMutableBytes { hashBytes in
                _ = CC_SHA256(plainBytes.baseAddress!, CC_LONG(plainBytes.count), hashBytes.baseAddress!)
            }
        }

        if hash != hash2 { throw ENCRYPT_ERR.PASSWORD }
    }
}
