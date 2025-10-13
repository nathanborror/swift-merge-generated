# Swift Merge

A Swift package for performing three-way merges using Myers' diff algorithm.

## Overview

This package provides a clean, efficient implementation of three-way merge functionality for Swift projects. It uses the Myers' diff algorithm to compute differences between sequences and intelligently merges divergent versions by using their common ancestor as a reference.

**Features:**
- ✅ Pure Swift implementation with no external dependencies
- ✅ Myers' diff algorithm for optimal edit script computation
- ✅ Three-way merge with automatic conflict detection
- ✅ Generic implementation works with any `Equatable` type
- ✅ Convenient string merging APIs for text files
- ✅ Comprehensive test coverage
- ✅ Well-documented with examples

## Installation

### Swift Package Manager

Add this package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-merge.git", from: "1.0.0")
]
```

Then add `Merge` as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Merge"]
)
```

## Usage

### Basic Three-Way Merge

```swift
import Merge

let base = ["A", "B", "C", "D"]
let ours = ["A", "X", "C", "D"]     // Changed B to X
let theirs = ["A", "B", "C", "Y"]   // Changed D to Y

let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)

switch result {
case .success(let merged):
    print("Merged successfully:", merged)
    // Output: ["A", "X", "C", "Y"]
    
case .conflict(let conflict):
    print("Conflicts detected:")
    for region in conflict.conflicts {
        print("  Base:", region.base)
        print("  Ours:", region.ours)
        print("  Theirs:", region.theirs)
    }
}
```

### Merging Text Files

```swift
import Merge

let base = """
function greet() {
  console.log("Hello");
}
"""

let ours = """
function greet(name) {
  console.log("Hello");
}
"""

let theirs = """
function greet() {
  console.log("Hello, World!");
}
"""

let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

switch result {
case .success(let merged):
    print(merged)
    // Merged successfully with both changes
    
case .conflict(let conflict):
    print("Conflicts at lines:", conflict.conflicts.map { $0.startLine })
    
    // Format conflicts with standard markers
    for region in conflict.conflicts {
        print(region.formatAsConflictMarkers())
    }
}
```

### Computing Diffs

```swift
import Merge

let original = ["A", "B", "C"]
let modified = ["A", "X", "C"]

let changes = Merge.diff(original: original, modified: modified)

for change in changes {
    print(change)
}

// Output:
//   [0] A
// - [1] B
// + [1] X
//   [2] C
```

### String Diffs

```swift
import Merge

let original = "Hello\nWorld\n"
let modified = "Hello\nSwift\nWorld\n"

let changes = Merge.diffStrings(original: original, modified: modified)

for change in changes {
    switch change {
    case .insert(let line, let content):
        print("+ Line \(line): \(content)")
    case .delete(let line, let content):
        print("- Line \(line): \(content)")
    case .equal(let line, let content):
        print("  Line \(line): \(content)")
    }
}
```

## API Reference

### `Merge` (Main API)

#### Three-Way Merge

```swift
static func threeWay<Element: Equatable>(
    base: [Element],
    ours: [Element],
    theirs: [Element]
) -> ThreeWayMerge<Element>.MergeResult
```

Performs a three-way merge on sequences of equatable elements.

**Parameters:**
- `base`: The common ancestor sequence
- `ours`: The local changes
- `theirs`: The remote changes

**Returns:** `MergeResult` which is either `.success([Element])` or `.conflict(MergeConflict)`

---

```swift
static func threeWayStrings(
    base: String,
    ours: String,
    theirs: String,
    separator: String = "\n"
) -> StringMergeResult
```

Performs a three-way merge on strings by splitting them into lines.

**Parameters:**
- `base`: The common ancestor string
- `ours`: The local changes
- `theirs`: The remote changes
- `separator`: The line separator (default: `"\n"`)

**Returns:** `StringMergeResult` which is either `.success(String)` or `.conflict(StringMergeConflict)`

#### Diff Computation

```swift
static func diff<Element: Equatable>(
    original: [Element],
    modified: [Element]
) -> [MyersDiff<Element>.Change]
```

Computes the differences between two sequences using Myers' diff algorithm.

---

```swift
static func diffStrings(
    original: String,
    modified: String,
    separator: String = "\n"
) -> [MyersDiff<String>.Change]
```

Computes differences between strings by splitting them into lines.

### `MyersDiff<Element>`

The Myers' diff implementation for computing differences between sequences.

```swift
struct MyersDiff<Element: Equatable> {
    init(original: [Element], modified: [Element])
    func diff() -> [Change]
}
```

**Change Types:**
- `.delete(index: Int, element: Element)` - Element was deleted
- `.insert(index: Int, element: Element)` - Element was inserted
- `.equal(index: Int, element: Element)` - Element remained the same

### `ThreeWayMerge<Element>`

The three-way merge implementation.

```swift
struct ThreeWayMerge<Element: Equatable> {
    init(base: [Element], ours: [Element], theirs: [Element])
    func merge() -> MergeResult
}
```

**MergeResult:**
- `.success([Element])` - Merge completed successfully
- `.conflict(MergeConflict)` - Conflicts were detected

**MergeConflict:**
```swift
struct MergeConflict {
    let partial: [Element]           // Merged content up to conflicts
    let conflicts: [ConflictRegion]  // All conflict regions
}
```

**ConflictRegion:**
```swift
struct ConflictRegion {
    let base: [Element]      // Base version
    let ours: [Element]      // Our version
    let theirs: [Element]    // Their version
    let startIndex: Int      // Where conflict starts
}
```

## How It Works

### Myers' Diff Algorithm

The package implements Eugene W. Myers' O(ND) difference algorithm, which finds the shortest edit script (SES) to transform one sequence into another. The algorithm:

1. Treats the problem as finding a path through an edit graph
2. Uses dynamic programming to explore possible edit paths
3. Returns the optimal sequence of insertions, deletions, and matches

### Three-Way Merge

The three-way merge algorithm:

1. Computes diffs from the base to both variants (ours and theirs)
2. Groups consecutive changes into edit regions
3. Merges non-overlapping edits automatically
4. Detects conflicts when both sides modify the same region
5. Returns either a successful merge or detailed conflict information

**Non-conflicting scenarios:**
- Only one side made changes
- Both sides made identical changes
- Changes are in different, non-overlapping regions

**Conflicting scenarios:**
- Both sides modified the same content differently
- One side deleted what the other modified
- Both sides inserted different content at the same location

## Examples

### Example 1: Code File Merge

```swift
let base = """
import Foundation

struct User {
    let name: String
}
"""

let ours = """
import Foundation

struct User {
    let name: String
    let email: String
}
"""

let theirs = """
import Foundation
import SwiftUI

struct User {
    let name: String
}
"""

let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

// Result: Both imports and email field are merged successfully
```

### Example 2: Configuration Merge

```swift
let base = ["debug=false", "port=8080"]
let ours = ["debug=true", "port=8080"]   // Changed debug
let theirs = ["debug=false", "port=9000"] // Changed port

let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)

// Result: ["debug=true", "port=9000"]
```

### Example 3: Handling Conflicts

```swift
let base = ["version: 1.0"]
let ours = ["version: 1.1"]
let theirs = ["version: 2.0"]

let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)

if case .conflict(let conflict) = result {
    for region in conflict.conflicts {
        print("Conflict detected!")
        print("Base:   \(region.base)")
        print("Ours:   \(region.ours)")
        print("Theirs: \(region.theirs)")
        
        // Resolve manually or present to user
        let resolved = resolveConflict(region)
    }
}
```

## Testing

The package includes comprehensive test coverage:

- **MyersDiffTests**: Tests for the Myers' diff algorithm
  - Empty sequences, identical sequences
  - Single and multiple insertions/deletions
  - Replacements and complex scenarios
  - Different data types (strings, integers)

- **ThreeWayMergeTests**: Tests for three-way merge
  - Non-conflicting merges
  - Conflict detection
  - Identical changes
  - Edge cases (empty files, adjacent changes)

- **MergeTests**: Integration tests for public API
  - String merging scenarios
  - Real-world use cases
  - Conflict marker formatting

Run tests with:

```bash
swift test
```

## Performance

The Myers' diff algorithm has:
- **Time complexity:** O(ND) where N is the sum of lengths and D is the size of the minimum edit script
- **Space complexity:** O(N) for storing the edit graph

For typical use cases (small to medium-sized files with few differences), performance is excellent. For very large files or files with many differences, consider:
- Breaking files into smaller chunks
- Using line-based diffing (already default for strings)
- Caching diff results when possible

## Requirements

- Swift 6.2+
- iOS 18.0+ / macOS 15.0+ (for test framework)
- No external dependencies

## License

MIT License - feel free to use this in your projects!

## Credits

Based on "An O(ND) Difference Algorithm and Its Variations" by Eugene W. Myers (1986).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## References

- [Myers' Diff Algorithm Paper](http://www.xmailserver.org/diff2.pdf)
- [Three-Way Merge Overview](https://en.wikipedia.org/wiki/Merge_(version_control))