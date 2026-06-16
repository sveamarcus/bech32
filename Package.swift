// swift-tools-version: 6.2
import PackageDescription

// Applied to every Swift target: opt fully into the Swift 6 language mode so the
// whole package is checked under complete data-race safety on every platform.
let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

let package = Package(
    name: "bech32",
    // Minimum deployment targets for Apple platforms. Non-Apple platforms
    // (Linux, Android, Windows, WASI) are supported without an entry here.
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "bech32", targets: ["bech32"])
    ],
    targets: [
        .target(
            name: "bech32",
            dependencies: ["Cbech32"],
            swiftSettings: swiftSettings
        ),
        // Portable ISO-C reference implementation (sipa/bech32, vendored as a
        // git submodule under Sources/Cbech32). Compiles unchanged on every
        // supported platform.
        .target(
            name: "Cbech32",
            path: "Sources/Cbech32/ref/c",
            exclude: ["tests.c"],
            sources: ["segwit_addr.c"],
            // `publicHeadersPath` already places this directory on the include path
            // and propagates it to the `bech32` target, so no extra `cSettings`
            // (header search paths) are required — keeping the manifest portable.
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "bech32Tests",
            dependencies: ["bech32"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
