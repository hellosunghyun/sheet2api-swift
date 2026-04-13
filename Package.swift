// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sheet2api-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Sheet2APISwift",
            targets: ["Sheet2APISwift"]
        ),
        .executable(
            name: "sheet2api-swift-example",
            targets: ["Sheet2APISwiftExample"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "Sheet2APISwift",
            path: "Sources/Sheet2APISwift"
        ),
        .executableTarget(
            name: "Sheet2APISwiftExample",
            dependencies: ["Sheet2APISwift"],
            path: "Sources/Sheet2APISwiftExample"
        ),
        .testTarget(
            name: "Sheet2APISwiftTests",
            dependencies: [
                "Sheet2APISwift",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/Sheet2APISwiftTests"
        )
    ]
)
