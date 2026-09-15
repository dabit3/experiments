// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevinCreative",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DevinCore", targets: ["DevinCore"]),
        .executable(name: "DevinStudio", targets: ["DevinStudio"])
    ],
    targets: [
        .target(name: "DevinCore"),
        .executableTarget(name: "DevinStudio", dependencies: ["DevinCore"]),
        .testTarget(name: "DevinCoreTests", dependencies: ["DevinCore"])
    ],
    swiftLanguageModes: [.v5]
)
