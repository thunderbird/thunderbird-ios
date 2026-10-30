// swift-tools-version: 6.2

import PackageDescription

let package: Package = Package(
    name: "Bolt",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Bolt",
            targets: [
                "Bolt"
            ]),
        .library(
            name: "BoltUI",
            targets: [
                "BoltUI"
            ])
    ],
    targets: [
        .target(
            name: "Bolt",
            dependencies: [
                "BoltUI"
            ]),
        .target(
            name: "BoltUI"),
        .testTarget(
            name: "BoltUITests",
            dependencies: [
                "BoltUI"
            ])
    ])
