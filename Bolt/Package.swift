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
            name: "BoltUI",
            targets: [
                "BoltUI"
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/thunderbird/bolt-design-system", branch: "main")
    ],
    targets: [
        .target(
            name: "BoltUI",
            dependencies: [
                .product(name: "BoltDesignSystem", package: "bolt-design-system")
            ]),
        .testTarget(
            name: "BoltUITests",
            dependencies: [
                "BoltUI"
            ])
    ])
