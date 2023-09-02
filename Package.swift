// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = {
    var settings: [SwiftSetting] = []
    #if os(Windows)
    settings.append(contentsOf: [
        // This is required on Windows due to a bug
        // SR-12683 https://github.com/apple/swift/issues/55127
        .unsafeFlags(["-parse-as-library"], .when(platforms: [.windows])),
        
        // These flags tell Windows that the executable is UI based (shows a window) and hides the command prompt
        .unsafeFlags(["-Xfrontend", "-entry-point-function-name"], .when(platforms: [.windows], configuration: .release)),
        .unsafeFlags(["-Xfrontend", "wWinMain"], .when(platforms: [.windows], configuration: .release)),
    ])
    #endif
    return settings
}()

let linkerSettings: [LinkerSetting] = {
    var settings: [LinkerSetting] = []
    #if os(Windows)
    settings.append(contentsOf: [
        // These flags tell Windows that the executable is UI based (shows a window) and hides the command prompt
        .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(platforms: [.windows], configuration: .release)),
    ])
    #endif
    return settings
}()

let package: Package = Package(
    name: "GateEngineDemos",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .executable(name: "01_UserInput", targets: ["_01_UserInput"]),
        .executable(name: "02_MultipleWindows", targets: ["_02_MultipleWindows"]),
        .executable(name: "03_SavingState", targets: ["_03_SavingState"]),
        
        .executable(name: "2D_01_AnimatedSprite", targets: ["2D_01_AnimatedSprite"]),
        .executable(name: "2D_Pong", targets: ["2D_Pong"]),
        
        .executable(name: "3D_01_RotatingCube", targets: ["3D_01_RotatingCube"]),
        .executable(name: "3D_02_SkinnedCharacter", targets: ["3D_02_SkinnedCharacter"]),
        .executable(name: "3D_03_MousePicking", targets: ["3D_03_MousePicking"]),
        .executable(name: "3D_FirstPerson", targets: ["3D_FirstPerson"]),
    ],
    dependencies: [
        .package(url: "https://github.com/STREGAsGate/GateEngine.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "_01_UserInput",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "_02_MultipleWindows",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        .executableTarget(name: "_03_SavingState",
                          dependencies: ["GateEngine"],
                          swiftSettings: swiftSettings,
                          linkerSettings: linkerSettings),
        
        .executableTarget(name: "2D_01_AnimatedSprite",
                          dependencies: ["GateEngine"],
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
    ]
)
