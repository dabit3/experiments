// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SugarTetherRules",
    products: [.library(name: "SugarTetherRules", targets: ["SugarTetherRules"])],
    targets: [
        .target(name: "SugarTetherRules", path: "Sources/Core"),
        .testTarget(name: "SugarTetherTests", dependencies: ["SugarTetherRules"], path: "Tests"),
    ]
)
