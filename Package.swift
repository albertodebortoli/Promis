// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "Promis",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Promis",
            targets: ["Promis"])
    ],
    targets: [
        .target(
            name: "Promis",
            path: "Framework/Sources"),
        .testTarget(
            name: "PromisTests",
            dependencies: ["Promis"],
            path: "Tests/Sources")
    ]
)
