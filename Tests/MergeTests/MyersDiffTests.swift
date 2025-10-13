import Testing

@testable import Merge

@Suite("Myers' Diff Algorithm Tests")
struct MyersDiffTests {

    @Test("Empty sequences produce no changes")
    func testEmptySequences() {
        let original: [String] = []
        let modified: [String] = []

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.isEmpty)
    }

    @Test("Identical sequences produce only equal changes")
    func testIdenticalSequences() {
        let original = ["A", "B", "C"]
        let modified = ["A", "B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        for change in changes {
            if case .equal = change {
                // Expected
            } else {
                Issue.record("Expected only equal changes, got \(change)")
            }
        }
    }

    @Test("Single insertion at the beginning")
    func testSingleInsertionAtBeginning() {
        let original = ["B", "C"]
        let modified = ["A", "B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)

        guard case .insert(let idx, let elem) = changes[0] else {
            Issue.record("Expected insert at position 0")
            return
        }
        #expect(idx == 0)
        #expect(elem == "A")
    }

    @Test("Single insertion in the middle")
    func testSingleInsertionInMiddle() {
        let original = ["A", "C"]
        let modified = ["A", "B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .insert(index: 1, element: "B"))
        #expect(changes[2] == .equal(index: 1, element: "C"))
    }

    @Test("Single insertion at the end")
    func testSingleInsertionAtEnd() {
        let original = ["A", "B"]
        let modified = ["A", "B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[2] == .insert(index: 2, element: "C"))
    }

    @Test("Single deletion at the beginning")
    func testSingleDeletionAtBeginning() {
        let original = ["A", "B", "C"]
        let modified = ["B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .delete(index: 0, element: "A"))
        #expect(changes[1] == .equal(index: 1, element: "B"))
        #expect(changes[2] == .equal(index: 2, element: "C"))
    }

    @Test("Single deletion in the middle")
    func testSingleDeletionInMiddle() {
        let original = ["A", "B", "C"]
        let modified = ["A", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .equal(index: 2, element: "C"))
    }

    @Test("Single deletion at the end")
    func testSingleDeletionAtEnd() {
        let original = ["A", "B", "C"]
        let modified = ["A", "B"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .equal(index: 1, element: "B"))
        #expect(changes[2] == .delete(index: 2, element: "C"))
    }

    @Test("Replacement (delete and insert)")
    func testReplacement() {
        let original = ["A", "B", "C"]
        let modified = ["A", "X", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 4)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .insert(index: 1, element: "X"))
        #expect(changes[3] == .equal(index: 2, element: "C"))
    }

    @Test("Multiple insertions")
    func testMultipleInsertions() {
        let original = ["A", "D"]
        let modified = ["A", "B", "C", "D"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 4)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .insert(index: 1, element: "B"))
        #expect(changes[2] == .insert(index: 2, element: "C"))
        #expect(changes[3] == .equal(index: 1, element: "D"))
    }

    @Test("Multiple deletions")
    func testMultipleDeletions() {
        let original = ["A", "B", "C", "D"]
        let modified = ["A", "D"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 4)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .delete(index: 2, element: "C"))
        #expect(changes[3] == .equal(index: 3, element: "D"))
    }

    @Test("Complete replacement")
    func testCompleteReplacement() {
        let original = ["A", "B", "C"]
        let modified = ["X", "Y", "Z"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 6)
        // Should delete all original elements and insert all new ones
    }

    @Test("Insert into empty sequence")
    func testInsertIntoEmpty() {
        let original: [String] = []
        let modified = ["A", "B", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .insert(index: 0, element: "A"))
        #expect(changes[1] == .insert(index: 1, element: "B"))
        #expect(changes[2] == .insert(index: 2, element: "C"))
    }

    @Test("Delete all elements")
    func testDeleteAll() {
        let original = ["A", "B", "C"]
        let modified: [String] = []

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 3)
        #expect(changes[0] == .delete(index: 0, element: "A"))
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .delete(index: 2, element: "C"))
    }

    @Test("Complex mixed operations")
    func testComplexMixedOperations() {
        let original = ["A", "B", "C", "D", "E"]
        let modified = ["A", "X", "C", "Y", "E", "F"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        // Verify we got changes
        #expect(!changes.isEmpty)

        // Count each type of change
        let deletions = changes.filter {
            if case .delete = $0 { return true }
            return false
        }
        let insertions = changes.filter {
            if case .insert = $0 { return true }
            return false
        }
        let equals = changes.filter {
            if case .equal = $0 { return true }
            return false
        }

        #expect(deletions.count == 2)  // B, D
        #expect(insertions.count == 3)  // X, Y, F
        #expect(equals.count == 3)  // A, C, E
    }

    @Test("Diff with integers")
    func testDiffWithIntegers() {
        let original = [1, 2, 3, 4, 5]
        let modified = [1, 2, 7, 8, 5]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(!changes.isEmpty)

        // Verify structure
        #expect(changes[0] == .equal(index: 0, element: 1))
        #expect(changes[1] == .equal(index: 1, element: 2))
        #expect(changes[2] == .delete(index: 2, element: 3))
        #expect(changes[3] == .delete(index: 3, element: 4))
        #expect(changes[4] == .insert(index: 2, element: 7))
        #expect(changes[5] == .insert(index: 3, element: 8))
        #expect(changes[6] == .equal(index: 4, element: 5))
    }

    @Test("Longest common subsequence example")
    func testLongestCommonSubsequence() {
        // Classic LCS example: ABCABBA and CBABAC
        let original = ["A", "B", "C", "A", "B", "B", "A"]
        let modified = ["C", "B", "A", "B", "A", "C"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        // Should find a valid edit script
        #expect(!changes.isEmpty)

        // The result should preserve common elements
        let equals = changes.filter {
            if case .equal = $0 { return true }
            return false
        }
        #expect(equals.count >= 4)  // At least BABA should be common
    }

    @Test("Single character difference")
    func testSingleCharacterDifference() {
        let original = ["H", "e", "l", "l", "o"]
        let modified = ["H", "e", "l", "l", "o", "!"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        #expect(changes.count == 6)
        #expect(changes[5] == .insert(index: 5, element: "!"))
    }

    @Test("Reversed sequence")
    func testReversedSequence() {
        let original = ["A", "B", "C"]
        let modified = ["C", "B", "A"]

        let diff = MyersDiff(original: original, modified: modified)
        let changes = diff.diff()

        // Should produce a valid diff
        #expect(!changes.isEmpty)

        // At least B should be preserved in some form
        let hasB = changes.contains { change in
            switch change {
            case .equal(_, "B"), .insert(_, "B"), .delete(_, "B"):
                return true
            default:
                return false
            }
        }
        #expect(hasB)
    }
}
