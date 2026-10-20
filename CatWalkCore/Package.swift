// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatWalkCore",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0"),
        .watchOS("26.0"),
    ],
    products: [
        .library(name: "CatWalkCore", targets: ["CatWalkCore"]),
    ],
    targets: [
        .target(name: "CatWalkCore"),
        .testTarget(name: "CatWalkCoreTests", dependencies: ["CatWalkCore"]),
    ],
    swiftLanguageModes: [.v6]
)
