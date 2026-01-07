// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeyImServer",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // Vapor framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        // Apple's Stable Diffusion framework
        .package(url: "https://github.com/apple/ml-stable-diffusion.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "HeyImServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "StableDiffusion", package: "ml-stable-diffusion"),
            ],
            path: "Sources"
        ),
    ]
)
