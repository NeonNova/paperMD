// swift-tools-version:6.0
import PackageDescription

// Deployment target is macOS 26.0 — matched to this machine (macOS 26.x) and
// the toolchain's default target (arm64-apple-macosx26.0). The named `.v26`
// platform constant does not exist in this SwiftPM yet, so the string-literal
// form is used. Swift 5 language mode avoids strict-concurrency friction with
// AppKit APIs while still building on the Swift 6.3 toolchain.
//
// Test strategy: this Command Line Tools install (no Xcode) ships neither a
// usable XCTest module nor the swift-testing runtime for `swift test`, so the
// test target is a plain executable that runs assertions via TestKit and is
// invoked with `swift run paperMDTests` (exit code 0 = pass, 1 = fail).
// Pure, testable code lives in the paperMDCore library; the paperMD executable
// holds the SwiftUI/AppKit UI layer.
let mode: SwiftSetting = .swiftLanguageMode(.v5)

let package = Package(
    name: "paperMD",
    platforms: [.macOS("26.0")],
    targets: [
        .target(
            name: "paperMDCore",
            path: "Sources/paperMDCore",
            swiftSettings: [mode]
        ),
        .executableTarget(
            name: "paperMD",
            dependencies: ["paperMDCore"],
            path: "Sources/paperMD",
            resources: [.copy("Resources")],
            swiftSettings: [mode]
        ),
        .executableTarget(
            name: "paperMDTests",
            dependencies: ["paperMDCore"],
            path: "Tests/paperMDTests",
            swiftSettings: [mode]
        ),
    ]
)
