import argon2
import CryptoKit
import Foundation

let VERSION = UInt8(1)

let VERSION_PREFIX_LEN = 1

let ARGON2ID_VERSION = 0x13
let ARGON2ID_ITERATIONS = UInt8(2)
let ARGON2ID_MEMORY_MB = UInt16(256)
let ARGON2ID_PARALLELISM = UInt8(2)
let ARGON2ID_KEY_LEN = 32
let ARGON2ID_SALT_LEN = 16

let CHACHAPOLY_NONCE_LEN = 12
let CHACHAPOLY_TAG_LEN = 16

enum ENCRYPT_ERR: Error {
    case FORMAT
    case AUTHENTICATION
    case CORE_KDF
    case CORE_CIPHER
}

let ENCRYPT_ERR_TEXT_FORMAT = "Invalid input data"
let ENCRYPT_ERR_TEXT_AUTHENTICATION = "Authentication failed"
let ENCRYPT_ERR_CORE_KDF = "Invoking key derivation failed"
let ENCRYPT_ERR_CORE_CIPHER = "Invoking cipher failed"

extension ENCRYPT_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FORMAT:
            return NSLocalizedString(ENCRYPT_ERR_TEXT_FORMAT, comment: ENCRYPT_ERR_TEXT_FORMAT)
        case .AUTHENTICATION:
            return NSLocalizedString(ENCRYPT_ERR_TEXT_AUTHENTICATION, comment: ENCRYPT_ERR_TEXT_AUTHENTICATION)
        case .CORE_KDF:
            return NSLocalizedString(ENCRYPT_ERR_CORE_KDF, comment: ENCRYPT_ERR_CORE_KDF)
        case .CORE_CIPHER:
            return NSLocalizedString(ENCRYPT_ERR_CORE_CIPHER, comment: ENCRYPT_ERR_CORE_CIPHER)
        }
    }
}

func encrypt(password: inout Data, plaintext: inout Data) throws -> Data {
    var key = Data(repeating: 0, count: ARGON2ID_KEY_LEN)
    let salt = try Data(randomOfLength: ARGON2ID_SALT_LEN)

    try key.withUnsafeMutableBytes { keyBytes in
        try salt.withUnsafeBytes { saltBytes in
            try password.withUnsafeBytes { passwordBytes in
                if argon2_hash(
                    UInt32(ARGON2ID_ITERATIONS),
                    1024 * UInt32(ARGON2ID_MEMORY_MB),
                    UInt32(ARGON2ID_PARALLELISM),
                    passwordBytes.baseAddress!,
                    password.count, saltBytes.baseAddress!,
                    ARGON2ID_SALT_LEN, keyBytes.baseAddress!,
                    ARGON2ID_KEY_LEN,
                    nil,
                    0,
                    Argon2_id,
                    UInt32(ARGON2ID_VERSION)
                ) != 0 { throw ENCRYPT_ERR.CORE_KDF }
            }
        }
    }

    do {
        return try
            Data([VERSION])
            + salt.subdata(in: 0 ..< ARGON2ID_SALT_LEN - CHACHAPOLY_NONCE_LEN)
            + ChaChaPoly.seal(
                plaintext,
                using: SymmetricKey(data: key),
                nonce: ChaChaPoly.Nonce(data: salt.subdata(in: ARGON2ID_SALT_LEN - CHACHAPOLY_NONCE_LEN ..< ARGON2ID_SALT_LEN))
            ).combined
    } catch {
        throw ENCRYPT_ERR.CORE_CIPHER
    }
}

func decrypt(password: inout Data, ciphertext: inout Data) throws -> Data {
    if ciphertext.count < VERSION_PREFIX_LEN + ARGON2ID_SALT_LEN + CHACHAPOLY_TAG_LEN || ciphertext[0] != VERSION { throw ENCRYPT_ERR.FORMAT }

    var key = Data(repeating: 0, count: ARGON2ID_KEY_LEN)
    let salt = ciphertext.subdata(in: VERSION_PREFIX_LEN ..< VERSION_PREFIX_LEN + ARGON2ID_SALT_LEN)

    try key.withUnsafeMutableBytes { keyBytes in
        try salt.withUnsafeBytes { saltBytes in
            try password.withUnsafeBytes { passwordBytes in
                if argon2_hash(
                    UInt32(ARGON2ID_ITERATIONS),
                    1024 * UInt32(ARGON2ID_MEMORY_MB),
                    UInt32(ARGON2ID_PARALLELISM),
                    passwordBytes.baseAddress!,
                    password.count,
                    saltBytes.baseAddress!,
                    ARGON2ID_SALT_LEN,
                    keyBytes.baseAddress!,
                    ARGON2ID_KEY_LEN,
                    nil,
                    0,
                    Argon2_id,
                    UInt32(ARGON2ID_VERSION)
                ) != 0 { throw ENCRYPT_ERR.CORE_KDF }
            }
        }
    }

    do {
        return try ciphertext.withUnsafeMutableBytes { cipherBytes in
            try ChaChaPoly.open(
                ChaChaPoly.SealedBox(
                    combined: Data(
                        bytesNoCopy: cipherBytes.baseAddress! + VERSION_PREFIX_LEN + ARGON2ID_SALT_LEN - CHACHAPOLY_NONCE_LEN,
                        count: cipherBytes.count - (VERSION_PREFIX_LEN + ARGON2ID_SALT_LEN - CHACHAPOLY_NONCE_LEN),
                        deallocator: .none
                    )),
                using: SymmetricKey(data: key)
            )
        }
    } catch CryptoKitError.authenticationFailure {
        throw ENCRYPT_ERR.AUTHENTICATION
    } catch {
        throw ENCRYPT_ERR.CORE_CIPHER
    }
}
