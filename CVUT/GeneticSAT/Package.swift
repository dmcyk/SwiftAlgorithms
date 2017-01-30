import PackageDescription

let package = Package(
    name: "Task5",
    targets: [
        Target(name: "Task5"),
        Target(name: "Executable", dependencies: [ .Target(name: "Task5") ])

        
    ],
    dependencies: [
        .Package(url: "https://github.com/dmcyk/cvut_utils", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/osjup/cvut_console.git", majorVersion: 0, minor: 9)
    ]
)
