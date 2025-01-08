// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "CursorBounds",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CursorBounds",
            targets: ["CursorBounds"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CursorBounds")
    ]
)
