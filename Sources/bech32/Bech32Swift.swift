//===----------------------------------------------------------------------===//
//
// This source file is part of the fltrECC open source project
//
// Copyright (c) 2022-2026 fltrWallet AG and the fltrECC project authors
// Licensed under Apache License v2.0
//
// See LICENSE.md for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Cbech32

/// A namespace for Bech32 / Bech32m and SegWit address encoding and decoding.
public struct Bech32 {}

extension Bech32 {
    /// Errors thrown by ``Bech32`` encoding and decoding operations.
    public enum Error: Swift.Error, Sendable, Hashable {
        /// A low-level Bech32 string could not be encoded.
        case bech32Encode
        /// A low-level Bech32 string could not be decoded.
        case bech32Decode
        /// A SegWit address could not be decoded for the requested network.
        case decodeSegWitAddress
        /// A SegWit address could not be encoded.
        case encodeSegWitAddress
        /// The supplied human readable part contained an uppercase character.
        case hrpHasUppercase
    }
}

extension Bech32 {
    /// The human readable part (network prefix) of a SegWit address.
    public enum HumanReadablePart: String, Sendable, Hashable, CaseIterable {
        /// Bitcoin mainnet (`bc`).
        case main = "bc"
        /// Bitcoin testnet (`tb`).
        case testnet = "tb"
    }
}

extension Bech32 {
    /// Decodes a NUL-terminated C string buffer into a Swift `String`
    @inlinable
    static func decodeCString(_ buffer: [CChar]) -> String {
        String(decoding: buffer.prefix { $0 != 0 }.lazy.map(UInt8.init(bitPattern:)), as: UTF8.self)
    }
}

extension Bech32 {
    /// A decoded SegWit witness program: its version (`0...16`) and the program bytes.
    public typealias WitnessProgram = (version: Int, program: [UInt8])

    /// Encodes a SegWit (BIP-173 / BIP-350) address.
    ///
    /// - Parameters:
    ///   - hrp: The network prefix to encode.
    ///   - version: The witness version, in the range `0...16`.
    ///   - witnessProgram: The witness program bytes, `2...40` bytes long.
    /// - Returns: The lowercased, checksummed SegWit address.
    /// - Throws: ``Error/encodeSegWitAddress`` if the inputs cannot be encoded.
    @inlinable
    public static func addressEncode(
        _ hrp: HumanReadablePart,
        version: Int,
        witnessProgram: [UInt8]
    ) throws(Error) -> String {
        assert(version >= 0 && version <= 16)
        assert(witnessProgram.count >= 2 && witnessProgram.count <= 40)

        let cHrp = Array(hrp.rawValue.utf8CString)
        let capacity = cHrp.count + 73
        var encoded = false
        let output = [CChar](unsafeUninitializedCapacity: capacity) { buffer, initializedCount in
            let result = witnessProgram.withUnsafeBufferPointer { program in
                segwit_addr_encode(
                    buffer.baseAddress!,
                    cHrp,
                    Int32(version),
                    program.baseAddress,
                    program.count
                )
            }
            if result == 1 {
                encoded = true
                initializedCount = buffer.firstIndex(of: 0).map { $0 + 1 } ?? capacity
            } else {
                initializedCount = 0
            }
        }

        guard encoded else { throw Error.encodeSegWitAddress }
        return Self.decodeCString(output)
    }

    /// Decodes a SegWit (BIP-173 / BIP-350) address for the given network.
    ///
    /// - Parameters:
    ///   - hrp: The expected network prefix.
    ///   - address: The address to decode.
    /// - Returns: The decoded ``WitnessProgram``.
    /// - Throws: ``Error/decodeSegWitAddress`` if `address` is not a valid SegWit
    ///   address for `hrp`.
    @inlinable
    public static func addressDecode(
        _ hrp: HumanReadablePart,
        address: String
    ) throws(Error) -> WitnessProgram {
        let cHrp = Array(hrp.rawValue.utf8CString)
        let cAddress = Array(address.utf8CString)
        var version: Int32 = -1
        var decoded = false
        let program = [UInt8](unsafeUninitializedCapacity: 40) { buffer, initializedCount in
            var length = buffer.count
            let result = segwit_addr_decode(&version, buffer.baseAddress!, &length, cHrp, cAddress)
            if result == 1, version >= 0 {
                decoded = true
                initializedCount = length
            } else {
                initializedCount = 0
            }
        }

        guard decoded else { throw Error.decodeSegWitAddress }
        return (Int(version), program)
    }

    /// Encodes arbitrary 5-bit data as a Bech32 string.
    ///
    /// - Parameters:
    ///   - hrp: The human readable part. Must be lowercase ASCII.
    ///   - data: The 5-bit data values to encode.
    /// - Returns: The lowercased, checksummed Bech32 string.
    /// - Throws: ``Error/bech32Encode`` if the inputs cannot be encoded.
    @inlinable
    public static func bech32Encode(_ hrp: String, data: [UInt8]) throws(Error) -> String {
        let cHrp = Array(hrp.utf8CString)
        let capacity = hrp.utf8.count + data.count + 8
        var encoded = false
        let output = [CChar](unsafeUninitializedCapacity: capacity) { buffer, initializedCount in
            let result = data.withUnsafeBufferPointer { data in
                bech32_encode(
                    buffer.baseAddress!, cHrp, data.baseAddress, data.count, BECH32_ENCODING_BECH32)
            }
            // The C routine NUL-terminates its output and writes nothing past it;
            // report exactly the written prefix to honour the initialization contract.
            if result == 1 {
                encoded = true
                initializedCount = buffer.firstIndex(of: 0).map { $0 + 1 } ?? capacity
            } else {
                initializedCount = 0
            }
        }

        guard encoded else { throw Error.bech32Encode }
        return Self.decodeCString(output)
    }

    /// Decodes a Bech32 or Bech32m string into its human readable part and 5-bit data.
    ///
    /// - Parameter input: The Bech32 / Bech32m string to decode.
    /// - Returns: The decoded human readable part and 5-bit data values.
    /// - Throws: ``Error/bech32Decode`` if `input` is not a valid Bech32 / Bech32m string.
    @inlinable
    public static func bech32Decode(_ input: String) throws(Error) -> (hrp: String, data: [UInt8]) {
        let cInput = Array(input.utf8CString)
        let inputLength = input.utf8.count
        var data: [UInt8] = []
        var decoded = false
        let hrp = [CChar](unsafeUninitializedCapacity: Swift.max(inputLength - 6, 1)) {
            hrpBuffer, hrpCount in
            data = [UInt8](unsafeUninitializedCapacity: Swift.max(inputLength, 1)) {
                dataBuffer, dataCount in
                var length = dataBuffer.count
                let result = bech32_decode(
                    hrpBuffer.baseAddress!, dataBuffer.baseAddress!, &length, cInput)
                if result == BECH32_ENCODING_BECH32 || result == BECH32_ENCODING_BECH32M {
                    decoded = true
                    dataCount = length
                } else {
                    dataCount = 0
                }
            }
            // The C routine writes the human readable part followed by a NUL terminator;
            // report exactly that many initialized elements (including the terminator).
            hrpCount = decoded ? (hrpBuffer.firstIndex(of: 0).map { $0 + 1 } ?? 0) : 0
        }

        guard decoded else { throw Error.bech32Decode }
        return (Self.decodeCString(hrp), data)
    }
}
