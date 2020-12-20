// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "apple-device-manager",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/ishkawa/APIKit.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "apple-device-manager",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "APIKit", package: "APIKit")
            ]),
        .testTarget(
            name: "apple-device-managerTests",
            dependencies: ["apple-device-manager"]),
    ]
)
