// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "doppler-xattr-util",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(
            name: "doppler-xattr-util",
            targets: ["doppler-xattr-util"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/brushedtype/doppler-xattr", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "doppler-xattr-util",
            dependencies: [
                .product(name: "DopplerExtendedAttributes", package: "doppler-xattr"),
            ]
        )
    ]
)
