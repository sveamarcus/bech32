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
import Testing

@testable import bech32

// MARK: - Test vectors

/// A valid SegWit address vector. `program` is the raw scriptPubKey: a witness
/// version byte, a push-length byte, then the witness program bytes.
private struct AddressVector: Sendable {
    let address: String
    let program: [UInt8]
    let hrp: Bech32.HumanReadablePart
}

private struct InvalidAddressVector: Sendable {
    let address: String
    let hrp: Bech32.HumanReadablePart
}

private let validAddresses: [AddressVector] = [
    AddressVector(
        address: "BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4",
        program: [
            0x00, 0x14, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54, 0x94, 0x1c, 0x45,
            0xd1,
            0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6,
        ],
        hrp: .main
    ),
    AddressVector(
        address: "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7",
        program: [
            0x00, 0x20, 0x18, 0x63, 0x14, 0x3c, 0x14, 0xc5, 0x16, 0x68, 0x04, 0xbd, 0x19, 0x20,
            0x33,
            0x56, 0xda, 0x13, 0x6c, 0x98, 0x56, 0x78, 0xcd, 0x4d, 0x27, 0xa1, 0xb8, 0xc6, 0x32,
            0x96,
            0x04, 0x90, 0x32, 0x62,
        ],
        hrp: .testnet
    ),
    AddressVector(
        address: "bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kt5nd6y",
        program: [
            0x51, 0x28, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54, 0x94, 0x1c, 0x45,
            0xd1,
            0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96,
            0xd4,
            0x54, 0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6,
        ],
        hrp: .main
    ),
    AddressVector(
        address: "BC1SW50QGDZ25J",
        program: [0x60, 0x02, 0x75, 0x1e],
        hrp: .main
    ),
    AddressVector(
        address: "bc1zw508d6qejxtdg4y5r3zarvaryvaxxpcs",
        program: [
            0x52, 0x10, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54, 0x94, 0x1c, 0x45,
            0xd1,
            0xb3, 0xa3, 0x23,
        ],
        hrp: .main
    ),
    AddressVector(
        address: "tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy",
        program: [
            0x00, 0x20, 0x00, 0x00, 0x00, 0xc4, 0xa5, 0xca, 0xd4, 0x62, 0x21, 0xb2, 0xa1, 0x87,
            0x90,
            0x5e, 0x52, 0x66, 0x36, 0x2b, 0x99, 0xd5, 0xe9, 0x1c, 0x6c, 0xe2, 0x4d, 0x16, 0x5d,
            0xab,
            0x93, 0xe8, 0x64, 0x33,
        ],
        hrp: .testnet
    ),
    AddressVector(
        address: "tb1pqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesf3hn0c",
        program: [
            0x51, 0x20, 0x00, 0x00, 0x00, 0xc4, 0xa5, 0xca, 0xd4, 0x62, 0x21, 0xb2, 0xa1, 0x87,
            0x90,
            0x5e, 0x52, 0x66, 0x36, 0x2b, 0x99, 0xd5, 0xe9, 0x1c, 0x6c, 0xe2, 0x4d, 0x16, 0x5d,
            0xab,
            0x93, 0xe8, 0x64, 0x33,
        ],
        hrp: .testnet
    ),
    AddressVector(
        address: "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0",
        program: [
            0x51, 0x20, 0x79, 0xbe, 0x66, 0x7e, 0xf9, 0xdc, 0xbb, 0xac, 0x55, 0xa0, 0x62, 0x95,
            0xce,
            0x87, 0x0b, 0x07, 0x02, 0x9b, 0xfc, 0xdb, 0x2d, 0xce, 0x28, 0xd9, 0x59, 0xf2, 0x81,
            0x5b,
            0x16, 0xf8, 0x17, 0x98,
        ],
        hrp: .main
    ),
]

private let invalidAddresses: [InvalidAddressVector] = [
    InvalidAddressVector(address: "tc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty", hrp: .testnet),
    InvalidAddressVector(address: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5", hrp: .main),
    InvalidAddressVector(address: "BC13W508D6QEJXTDG4Y5R3ZARVARY0C5XW7KN40WF2", hrp: .main),
    InvalidAddressVector(address: "bc1rw5uspcuh", hrp: .testnet),
    InvalidAddressVector(
        address: "bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90",
        hrp: .main
    ),
    InvalidAddressVector(
        address:
            "bca0w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90234567789035",
        hrp: .main
    ),
    InvalidAddressVector(address: "BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P", hrp: .main),
    InvalidAddressVector(
        address: "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7",
        hrp: .testnet
    ),
    InvalidAddressVector(address: "bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du", hrp: .main),
    InvalidAddressVector(
        address: "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv",
        hrp: .testnet
    ),
    InvalidAddressVector(address: "bc1gmk9yu", hrp: .main),
]

private let validChecksums: [String] = [
    "A12UEL5L",
    "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
    "abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw",
    "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j",
    "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w",
]

private let invalidChecksums: [String] = [
    " 1nwldj5",
    "\(0x7f)1axkwrx",
    "an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx",
    "pzry9x0s0muk",
    "1pzry9x0s0muk",
    "x1b4n0q5v",
    "li1dgmt3",
    "de1lg7wt\(0xff)",
]

// MARK: - Tests

@Suite("Bech32 / SegWit encoding")
struct Bech32Tests {
    @Test("Valid SegWit addresses decode and re-encode to themselves", arguments: validAddresses)
    private func addressRoundTrip(_ vector: AddressVector) throws {
        let decoded = try Bech32.addressDecode(vector.hrp, address: vector.address)
        #expect(decoded.program.count == Int(vector.program[1]))
        #expect(decoded.program == Array(vector.program[2...]))

        let reEncoded = try Bech32.addressEncode(
            vector.hrp,
            version: decoded.version,
            witnessProgram: decoded.program
        )
        #expect(reEncoded == vector.address.lowercased())
    }

    @Test("Invalid SegWit addresses are rejected", arguments: invalidAddresses)
    private func addressDecodeRejectsInvalid(_ vector: InvalidAddressVector) {
        #expect(throws: Bech32.Error.self) {
            try Bech32.addressDecode(vector.hrp, address: vector.address)
        }
    }

    @Test("Valid Bech32 strings decode and re-encode to themselves", arguments: validChecksums)
    private func bech32RoundTrip(_ checksum: String) throws {
        let (hrp, data) = try Bech32.bech32Decode(checksum)
        let rebuilt = try Bech32.bech32Encode(hrp, data: data)
        #expect(rebuilt == checksum.lowercased())
    }

    @Test("Invalid Bech32 strings are rejected", arguments: invalidChecksums)
    private func bech32DecodeRejectsInvalid(_ checksum: String) {
        #expect(throws: Bech32.Error.self) {
            try Bech32.bech32Decode(checksum)
        }
    }
}
