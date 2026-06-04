// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "native_geofence",
  platforms: [
    .iOS("14.0")
  ],
  products: [
    .library(name: "native-geofence", targets: ["native_geofence"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "native_geofence",
      dependencies: [],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    )
  ]
)
