// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "KeyboardBlocker",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "KeyboardBlocker",
            targets: ["KeyboardBlocker"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeyboardBlocker",
            dependencies: [],
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
) 