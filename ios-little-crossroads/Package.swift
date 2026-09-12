// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CrossroadsRules",
    platforms: [.macOS(.v13)],
    products: [.library(name: "CrossroadsRules", targets: ["CrossroadsRules"])],
    targets: [
        .target(name: "CrossroadsRules", path: "Sources/Core"),
        .testTarget(name: "CrossroadsRulesTests", dependencies: ["CrossroadsRules"], path: "Tests"),
    ]
)
