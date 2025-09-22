// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VroongFriendsPackages",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VroongFriendsPackages",
            targets: ["VroongFriendsPackages"]
        ),
    ],
    dependencies: [
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),

        // Dependency Injection
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),

        // Image Loading
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.0.0"),

        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0"),

        // Keychain
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),

        // Testing
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),

        // Lottie Animations (if needed)
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.3.0"),
    ],
    targets: [
        .target(
            name: "VroongFriendsPackages",
            dependencies: [
                "Alamofire",
                "Moya",
                "Swinject",
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                "KeychainAccess",
                .product(name: "Lottie", package: "lottie-spm"),
            ]
        ),
        .testTarget(
            name: "VroongFriendsPackagesTests",
            dependencies: [
                "VroongFriendsPackages",
                "Quick",
                "Nimble",
            ]
        ),
    ]
)