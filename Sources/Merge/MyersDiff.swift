/// Myers' diff algorithm implementation for computing differences between two sequences.
///
/// This implementation follows the algorithm described in "An O(ND) Difference Algorithm and Its Variations"
/// by Eugene W. Myers (1986). It finds the shortest edit script (SES) to transform one sequence into another.
public struct MyersDiff<Element: Equatable> {

    /// Represents a single difference operation
    public enum Change {
        /// An element was deleted from the original sequence at the given index
        case delete(index: Int, element: Element)
        /// An element was inserted into the original sequence at the given index
        case insert(index: Int, element: Element)
        /// An element remained the same in both sequences
        case equal(index: Int, element: Element)
    }

    private let original: [Element]
    private let modified: [Element]

    /// Creates a new diff instance for comparing two sequences
    /// - Parameters:
    ///   - original: The original sequence
    ///   - modified: The modified sequence
    public init(original: [Element], modified: [Element]) {
        self.original = original
        self.modified = modified
    }

    /// Computes the differences between the two sequences
    /// - Returns: An array of changes representing the edit script
    public func diff() -> [Change] {
        let n = original.count
        let m = modified.count
        let max = n + m

        // V[k] contains the furthest reaching x coordinate for diagonal k
        var v = [Int: Int]()
        v[1] = 0

        // Store the history of V for each edit distance d
        var trace: [[Int: Int]] = []

        // Find the shortest edit script
        for d in 0...max {
            trace.append(v)

            for k in stride(from: -d, through: d, by: 2) {
                // Determine if we should move down (insert) or right (delete)
                var x: Int
                if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                    // Move down (insert from modified)
                    x = v[k + 1] ?? 0
                } else {
                    // Move right (delete from original)
                    x = (v[k - 1] ?? 0) + 1
                }

                var y = x - k

                // Follow diagonal matches as far as possible
                while x < n && y < m && original[x] == modified[y] {
                    x += 1
                    y += 1
                }

                v[k] = x

                // Check if we've reached the end
                if x >= n && y >= m {
                    return backtrack(trace: trace, n: n, m: m)
                }
            }
        }

        // Should never reach here for valid input
        return []
    }

    /// Backtrack through the edit graph to construct the edit script
    private func backtrack(trace: [[Int: Int]], n: Int, m: Int) -> [Change] {
        var changes: [Change] = []
        var x = n
        var y = m

        for d in stride(from: trace.count - 1, through: 0, by: -1) {
            let v = trace[d]
            let k = x - y

            // Determine the previous k
            let prevK: Int
            if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                prevK = k + 1
            } else {
                prevK = k - 1
            }

            let prevX = v[prevK] ?? 0
            let prevY = prevX - prevK

            // Follow diagonals (matches) backward
            while x > prevX && y > prevY {
                x -= 1
                y -= 1
                changes.append(.equal(index: x, element: original[x]))
            }

            // Record the edit operation
            if d > 0 {
                if x == prevX {
                    // We moved down, so this was an insert
                    y -= 1
                    changes.append(.insert(index: y, element: modified[y]))
                } else {
                    // We moved right, so this was a delete
                    x -= 1
                    changes.append(.delete(index: x, element: original[x]))
                }
            }
        }

        return changes.reversed()
    }
}

extension MyersDiff.Change: Equatable where Element: Equatable {
    public static func == (lhs: MyersDiff<Element>.Change, rhs: MyersDiff<Element>.Change) -> Bool {
        switch (lhs, rhs) {
        case (.delete(let i1, let e1), .delete(let i2, let e2)):
            return i1 == i2 && e1 == e2
        case (.insert(let i1, let e1), .insert(let i2, let e2)):
            return i1 == i2 && e1 == e2
        case (.equal(let i1, let e1), .equal(let i2, let e2)):
            return i1 == i2 && e1 == e2
        default:
            return false
        }
    }
}

extension MyersDiff.Change: CustomStringConvertible {
    public var description: String {
        switch self {
        case .delete(let index, let element):
            return "- [\(index)] \(element)"
        case .insert(let index, let element):
            return "+ [\(index)] \(element)"
        case .equal(let index, let element):
            return "  [\(index)] \(element)"
        }
    }
}
