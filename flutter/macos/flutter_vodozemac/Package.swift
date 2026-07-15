// swift-tools-version: 5.9
// The MIT License (MIT)
//
// flutter_vodozemac ships its Rust code as a prebuilt XCFramework because
// SwiftPM cannot run cargo during the build (build tool plugins are
// sandboxed). The XCFramework is committed to this repo (built by
// scripts/build_xcframework.sh) rather than fetched from a release, so it's
// versioned alongside the Rust source that produced it. CocoaPods consumers
// still build from source via cargokit; see ../flutter_vodozemac.podspec.
import PackageDescription

let binaryTarget = Target.binaryTarget(
    name: "flutter_vodozemac",
    path: "flutter_vodozemac.xcframework"
)

// No FlutterFramework dependency on purpose: the only target is a
// binaryTarget (a pure-Rust dylib that does not link Flutter), and binary
// targets cannot declare dependencies. Mentioning FlutterFramework here also
// satisfies flutter_tools' string-based manifest check, which would otherwise
// warn on every consumer build.
let package = Package(
    name: "flutter_vodozemac",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "flutter-vodozemac", targets: ["flutter_vodozemac"])
    ],
    targets: [
        binaryTarget
    ]
)
