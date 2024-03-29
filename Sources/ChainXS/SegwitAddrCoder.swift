//
//  SegwitAddrCoder.swift
//
//  Created by Evolution Group Ltd on 12.02.2018.
//  Copyright © 2018 Evolution Group Ltd. All rights reserved.
//

//  Base32 address format for native v0-16 witness outputs implementation
//  https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
//  Inspired by Pieter Wuille C++ implementation

import Foundation

/// Segregated Witness Address encoder/decoder
public class SegwitAddrCoder {
    private let bech32 = Bech32Segwit()

    /// Decode segwit address
    public func decode(hrp: String, addr: String) throws -> (version: Int, program: Data) {
        let dec = try bech32.decode(addr)
        guard dec.hrp == hrp else {
            throw CoderError.hrpMismatch(dec.hrp, hrp)
        }
        guard dec.checksum.count >= 1 else {
            throw CoderError.checksumSizeTooLow
        }
        let conv = try dec.checksum.advanced(by: 1).convertBits(from: 5, to: 8, pad: false)
        guard conv.count >= 2, conv.count <= 40 else {
            throw CoderError.dataSizeMismatch(conv.count)
        }
        guard dec.checksum[0] <= 16 else {
            throw CoderError.segwitVersionNotSupported(dec.checksum[0])
        }
        if dec.checksum[0] == 0, conv.count != 20, conv.count != 32 {
            throw CoderError.segwitV0ProgramSizeMismatch(conv.count)
        }
        return (Int(dec.checksum[0]), conv)
    }

    /// Encode segwit address
    public func encode(hrp: String, version: Int, program: Data) throws -> String {
        var enc = Data([UInt8(version)])
        try enc.append(program.convertBits(from: 8, to: 5, pad: true))
        let result = bech32.encode(hrp, values: enc)
        guard let _ = try? decode(hrp: hrp, addr: result) else {
            throw CoderError.encodingCheckFailed
        }
        return result
    }
}

public extension SegwitAddrCoder {
    enum CoderError: LocalizedError {
        case hrpMismatch(String, String)
        case checksumSizeTooLow

        case dataSizeMismatch(Int)
        case segwitVersionNotSupported(UInt8)
        case segwitV0ProgramSizeMismatch(Int)

        case encodingCheckFailed

        public var errorDescription: String? {
            switch self {
            case .checksumSizeTooLow:
                return "Checksum size is too low"
            case let .dataSizeMismatch(size):
                return "Program size \(size) does not meet required range 2...40"
            case .encodingCheckFailed:
                return "Failed to check result after encoding"
            case let .hrpMismatch(got, expected):
                return "Human-readable-part \"\(got)\" does not match requested \"\(expected)\""
            case let .segwitV0ProgramSizeMismatch(size):
                return "Segwit program size \(size) does not meet version 0 requirments"
            case let .segwitVersionNotSupported(version):
                return "Segwit version \(version) is not supported by this decoder"
            }
        }
    }
}
