// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Promis",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Promis",
            targets: ["Promis"]),
    ],
    dependencies: [
        // Here we define our package's external dependencies
        // and from where they can be fetched:
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.1.1"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Promis",
            dependencies: ["ArgumentParser"],
            path: "./Promis/Classes/"),
        .testTarget(
            name: "PromisTests",
            dependencies: ["Promis"],
            path: "./Example/Tests/"),
    ]
)
