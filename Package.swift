// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "classic-pixel-editor",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ClassicPixelCore", targets: ["ClassicPixelCore"]),
        .executable(name: "ClassicPixelEditor", targets: ["ClassicPixelEditorApp"]),
        .executable(name: "ClassicPixelCoreTestRunner", targets: ["ClassicPixelCoreTestRunner"])
    ],
    targets: [
        .target(
            name: "ClassicPixelCore"
        ),
        .executableTarget(
            name: "ClassicPixelEditorApp",
            dependencies: ["ClassicPixelCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ImageIO"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        ),
        .executableTarget(
            name: "ClassicPixelCoreTestRunner",
            dependencies: ["ClassicPixelCore"]
        )
    ]
)
