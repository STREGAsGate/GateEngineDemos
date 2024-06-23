// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // Use whole cross optimization in release builds
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
    // Remove runtime checks in release builds
    .unsafeFlags(["-Ounchecked"], .when(configuration: .release)),
    
    // This is required on Windows due to a bug
    // #55127 https://github.com/apple/swift/issues/55127
    .unsafeFlags(["-parse-as-library"], .when(platforms: [.windows])),
    
    // These flags tell Windows that the executable is UI based (shows a window) and hides the command prompt
    .unsafeFlags(["-Xfrontend", "-entry-point-function-name"], .when(platforms: [.windows], configuration: .release)),
    .unsafeFlags(["-Xfrontend", "wWinMain"], .when(platforms: [.windows], configuration: .release)),
]

let linkerSettings: [LinkerSetting] = [
    // These flags tell Windows that the executable is UI based (shows a window) and hides the command prompt
    .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(platforms: [.windows], configuration: .release)),
]

let package: Package = Package(
    name: "GateEngineDemos",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .executable(name: "2D_01_AnimatedSprite", targets: ["2D_01_AnimatedSprite"]),
        .executable(name: "2D_JRPG", targets: ["2D_JRPG"]),
        .executable(name: "2D_Pong", targets: ["2D_Pong"]),
        
        .executable(name: "3D_01_RotatingCube", targets: ["3D_01_RotatingCube"]),
        .executable(name: "3D_02_SkinnedCharacter", targets: ["3D_02_SkinnedCharacter"]),
        .executable(name: "3D_03_MousePicking", targets: ["3D_03_MousePicking"]),
        .executable(name: "3D_FirstPerson", targets: ["3D_FirstPerson"]),
        
        .executable(name: "G_01_UserInput", targets: ["G_01_UserInput"]),
        .executable(name: "G_02_MultipleWindows", targets: ["G_02_MultipleWindows"]),
        .executable(name: "G_03_SavingState", targets: ["G_03_SavingState"]),
    ],
    dependencies: [
        .package(url: "https://github.com/STREGAsGate/GateEngine.git", branch: "Release-0.2"),
        .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "2D_01_AnimatedSprite",
                          dependencies: ["GateEngine"],
                          resources: [.copy("Resources")],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "2D_JRPG",
                          dependencies: ["GateEngine"],
                          exclude: ["Source Art"],
                          resources: [.copy("Resources")],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "2D_Pong",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        
        .executableTarget(name: "3D_01_RotatingCube",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "3D_02_SkinnedCharacter",
                          dependencies: ["GateEngine"],
                          resources: [.copy("Resources")],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "3D_03_MousePicking",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "3D_FirstPerson",
                          dependencies: ["GateEngine"],
                          resources: [.copy("Resources")],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        
        .executableTarget(name: "G_01_UserInput",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "G_02_MultipleWindows",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "G_03_SavingState",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
    ]
)
