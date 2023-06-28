// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LeavesDiagram",
    products: [
        .library(
            name: "LeavesDiagram",
            targets: ["LeavesDiagram"]),
    ],
    targets: [
        .target(name: "LeavesDiagram")
    ]
)
