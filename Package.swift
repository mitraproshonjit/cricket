// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CricketScorer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CricketScorer",
            targets: ["CricketScorer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0")
    ],
    targets: [
        .target(
            name: "CricketScorer",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ]
        )
    ]
)