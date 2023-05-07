// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GateEngineDemos",
    platforms: [.macOS(.v11), .iOS(.v13), .tvOS(.v13)],
    products: [
        .executable(name: "01_UserInput", targets: ["01_UserInput"]),
        
        .executable(name: "2D_01_AnimatedSprite", targets: ["2D_01_AnimatedSprite"]),
        
        .executable(name: "3D_01_RotatingCube", targets: ["3D_01_RotatingCube"]),
        .executable(name: "3D_02_SkinnedCharacter", targets: ["3D_02_SkinnedCharacter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/STREGAsGate/GateEngine.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "01_UserInput", dependencies: ["GateEngine"]),
        
        .executableTarget(name: "2D_01_AnimatedSprite", dependencies: ["GateEngine"], resources: [.copy("Resources")]),
    
        .executableTarget(name: "3D_01_RotatingCube", dependencies: ["GateEngine"]),
        .executableTarget(name: "3D_02_SkinnedCharacter", dependencies: ["GateEngine"], resources: [.copy("Resources")]),
    ]
)
