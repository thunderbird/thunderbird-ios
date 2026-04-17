// swift-tools-version: 6.2

import PackageDescription

let package: Package = Package(
    name: "Core",
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
            ]),
        .executable(
            name: "autoconfig",
            targets: [
                "AutoconfigurationCLI"
            ]),
        .library(
            name: "Autoconfiguration",
            targets: [
                "Autoconfiguration"
            ]),
        .library(
            name: "Core",
            targets: [
                "Core"
            ]),
        .library(
            name: "EmailAddress",
            targets: [
                "EmailAddress"
            ]),
        .library(
            name: "IMAP",
            targets: [
                "IMAP"
            ]),
        .library(
            name: "JMAP",
            targets: [
                "JMAP"
            ]),
        .library(
            name: "MIME",
            targets: [
                "MIME"
            ]),
        .library(
            name: "SMTP",
            targets: [
                "SMTP"
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-dns-resolver", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-extras", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-imap", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-ssl", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", branch: "main")
    ],
    targets: [
        .target(
            name: "Account",
            dependencies: [
                "Autoconfiguration",
                "EmailAddress",
                "IMAP",
                "JMAP",
                "MIME",
                "SMTP"
            ]),
        .testTarget(
            name: "AccountTests",
            dependencies: [
                "Account"
            ]),
        .target(
            name: "Autoconfiguration",
            dependencies: [
                .product(name: "AsyncDNSResolver", package: "swift-async-dns-resolver")
            ]),
        .executableTarget(
            name: "AutoconfigurationCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Autoconfiguration"
            ]),
        .testTarget(
            name: "AutoconfigurationTests",
            dependencies: [
                "Autoconfiguration"
            ]),
        .target(
            name: "Core",
            dependencies: [
                "Account"
            ]),
        .target(name: "EmailAddress"),
        .testTarget(
            name: "EmailAddressTests",
            dependencies: [
                "EmailAddress"
            ]),
        .target(
            name: "IMAP",
            dependencies: [
                .product(name: "NIOIMAP", package: "swift-nio-imap"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                "EmailAddress",
                "MIME"
            ]),
        .testTarget(
            name: "IMAPTests",
            dependencies: [
                "IMAP"
            ]),
        .target(
            name: "JMAP",
            dependencies: [
                "EmailAddress",
                "MIME"
            ]),
        .testTarget(
            name: "JMAPTests",
            dependencies: [
                "JMAP"
            ]),
        .target(name: "MIME"),
        .testTarget(
            name: "MIMETests",
            dependencies: [
                "MIME"
            ],
            resources: [
                .process("Resources")
            ]),
        .target(
            name: "SMTP",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                "EmailAddress",
                "MIME"
            ]),
        .testTarget(
            name: "SMTPTests",
            dependencies: [
                "SMTP"
            ])
    ])
