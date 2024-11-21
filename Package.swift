// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChainXS",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", from: "0.1.7"),
        .package(url: "https://github.com/bitflying/SwiftKeccak.git", from: "0.1.0"),
        .package(url: "https://github.com/raidshift/noxs", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "ChainXS",
            dependencies: [.product(name: "secp256k1", package: "secp256k1.swift"), "SwiftKeccak", .product(name: "NoXS", package: "noxs")]
        ),
    ]
)
