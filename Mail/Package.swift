// swift-tools-version: 6.0

import PackageDescription

let package: Package = Package(
    name: "Mail",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Account",
            targets: [
                "Account"
            ])
    ],
    targets: [
        .target(name: "Account"),
        .testTarget(
            name: "AccountTests",
            dependencies: [
                "Account"
            ])
    ])
