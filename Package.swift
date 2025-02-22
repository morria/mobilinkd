// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mobilinkd",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "mobilinkd",
            targets: ["mobilinkd"]),
        .executable(
            name: "aprs",
            targets: ["aprs"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "mobilinkd"),
        // Executable target that uses mobilinkd
        .executableTarget(
            name: "aprs",
            dependencies: [
                .target(name: "mobilinkd")
            ]
        ),
        .testTarget(
            name: "mobilinkdTests",
            dependencies: ["mobilinkd"]
        ),
    ]
)
