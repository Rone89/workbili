// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BiliBili",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "BiliBili", targets: ["BiliBili"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BiliBili",
            path: "BiliBili"
        ),
    ]
)
