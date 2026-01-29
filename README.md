# Merge

Three-way merge and diff using Myers' algorithm for Swift.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/nathanborror/swift-merge-generated.git", from: "1.0.0")
]
```

## Usage

```swift
import Merge

// Three-way merge
let result = Merge.threeWay(
    base: ["A", "B", "C"],
    ours: ["A", "X", "C"],
    theirs: ["A", "B", "Y"]
)

switch result {
case .success(let merged):
    print(merged) // ["A", "X", "Y"]
case .conflict(let conflict):
    print(conflict.conflicts)
}

// Diff
let changes = Merge.diff(original: ["A", "B"], modified: ["A", "C"])
```

String variants are also available: `Merge.threeWayStrings()` and `Merge.diffStrings()`.

## Tests

See the test suite for detailed usage examples and edge cases.