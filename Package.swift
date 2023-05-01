// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GateEngineDemos",
    platforms: [.macOS(.v11), .iOS(.v13), .tvOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/STREGAsGate/GateEngine.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "2D_01_AnimatedSprite", dependencies: ["GateEngine"], resources: [.copy("Resources")]),
        .executableTarget(name: "3D_01_RotatingCube", dependencies: ["GateEngine"]),
    ]
)
