// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pert",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "pert", targets: ["PertCLI"]),
        // .executable(name: "pert-gui", targets: ["PertGUI"]), // We will run this via swift run PertGUI, but it's an executable
        .library(name: "PertCore", targets: ["PertCore"])
    ],
    dependencies: [
        // Dependencies go here
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Shared Core Logic
        .target(
            name: "PertCore",
            dependencies: []
        ),
        // CLI Tool
        .executableTarget(
            name: "PertCLI",
            dependencies: [
                "PertCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        // GUI App
        .executableTarget(
            name: "PertGUI",
            dependencies: ["PertCore"],
            // Creating a proper .app bundle usually requires xcodebuild, but for 'swift run' we can just compile the executable.
            // We might need to handle Info.plist differently or just omit linker flags for simple development iteration.
            linkerSettings: [] 
        ),
    ]
)
