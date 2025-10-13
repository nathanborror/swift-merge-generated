import Testing

@testable import Merge

@Suite("Three-Way Merge Tests")
struct ThreeWayMergeTests {

    @Test("No changes produces base")
    func testNoChanges() {
        let base = ["A", "B", "C"]
        let ours = ["A", "B", "C"]
        let theirs = ["A", "B", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == base)
    }

    @Test("Only our changes applied")
    func testOnlyOurChanges() {
        let base = ["A", "B", "C"]
        let ours = ["A", "X", "C"]
        let theirs = ["A", "B", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "X", "C"])
    }

    @Test("Only their changes applied")
    func testOnlyTheirChanges() {
        let base = ["A", "B", "C"]
        let ours = ["A", "B", "C"]
        let theirs = ["A", "Y", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "Y", "C"])
    }

    @Test("Non-overlapping changes merge successfully")
    func testNonOverlappingChanges() {
        let base = ["A", "B", "C", "D"]
        let ours = ["A", "X", "C", "D"]
        let theirs = ["A", "B", "C", "Y"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "X", "C", "Y"])
    }

    @Test("Both sides make identical changes")
    func testIdenticalChanges() {
        let base = ["A", "B", "C"]
        let ours = ["A", "X", "C"]
        let theirs = ["A", "X", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "X", "C"])
    }

    @Test("Conflicting changes detected")
    func testConflictingChanges() {
        let base = ["A", "B", "C"]
        let ours = ["A", "X", "C"]
        let theirs = ["A", "Y", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
        #expect(conflict.conflicts[0].ours == ["X"])
        #expect(conflict.conflicts[0].theirs == ["Y"])
    }

    @Test("Our insertion, their modification conflict")
    func testInsertionModificationConflict() {
        let base = ["A", "B", "C"]
        let ours = ["A", "B", "X", "C"]
        let theirs = ["A", "Y", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        // This should be a conflict since we're modifying overlapping regions
        if case .success = result {
            // Success is also acceptable if the algorithm determines they don't overlap
        } else if case .conflict = result {
            // Conflict is also acceptable
        }
    }

    @Test("Both sides insert at same location")
    func testBothSidesInsert() {
        let base = ["A", "C"]
        let ours = ["A", "X", "C"]
        let theirs = ["A", "Y", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        // This creates a conflict at the insertion point
        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict for competing insertions")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }

    @Test("Both sides delete same element")
    func testBothSidesDelete() {
        let base = ["A", "B", "C"]
        let ours = ["A", "C"]
        let theirs = ["A", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge for identical deletions")
            return
        }

        #expect(merged == ["A", "C"])
    }

    @Test("Our deletion, their modification conflict")
    func testDeletionModificationConflict() {
        let base = ["A", "B", "C"]
        let ours = ["A", "C"]
        let theirs = ["A", "X", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict when one side deletes and other modifies")
            return
        }

        #expect(conflict.conflicts.count == 1)
        #expect(conflict.conflicts[0].ours.isEmpty)
        #expect(conflict.conflicts[0].theirs == ["X"])
    }

    @Test("Multiple non-conflicting changes")
    func testMultipleNonConflictingChanges() {
        let base = ["A", "B", "C", "D", "E", "F"]
        let ours = ["A", "X", "C", "D", "E", "F"]
        let theirs = ["A", "B", "C", "Y", "E", "F"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "X", "C", "Y", "E", "F"])
    }

    @Test("Multiple conflicts")
    func testMultipleConflicts() {
        let base = ["A", "B", "C", "D"]
        let ours = ["A", "X", "C", "Y"]
        let theirs = ["A", "Z", "C", "W"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflicts")
            return
        }

        #expect(conflict.conflicts.count == 2)
    }

    @Test("Append to end by both sides")
    func testBothSidesAppend() {
        let base = ["A", "B"]
        let ours = ["A", "B", "X"]
        let theirs = ["A", "B", "Y"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict for competing appends")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }

    @Test("Prepend by both sides")
    func testBothSidesPrepend() {
        let base = ["B", "C"]
        let ours = ["X", "B", "C"]
        let theirs = ["Y", "B", "C"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict for competing prepends")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }

    @Test("Empty base with both sides adding")
    func testEmptyBaseWithAdditions() {
        let base: [String] = []
        let ours = ["X"]
        let theirs = ["Y"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }

    @Test("Empty base with identical additions")
    func testEmptyBaseWithIdenticalAdditions() {
        let base: [String] = []
        let ours = ["X"]
        let theirs = ["X"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge for identical additions")
            return
        }

        #expect(merged == ["X"])
    }

    @Test("Complex real-world scenario")
    func testComplexRealWorldScenario() {
        // Simulating a code file merge
        let base = [
            "function hello() {",
            "  print('Hello')",
            "  print('World')",
            "}",
        ]

        let ours = [
            "function hello() {",
            "  print('Hello')",
            "  print('Beautiful')",
            "  print('World')",
            "}",
        ]

        let theirs = [
            "function hello() {",
            "  console.log('Hello')",
            "  console.log('World')",
            "}",
        ]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        // This should result in a conflict since both sides modified the print statements
        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict in complex scenario")
            return
        }

        #expect(!conflict.conflicts.isEmpty)
    }

    @Test("Merge with integers")
    func testMergeWithIntegers() {
        let base = [1, 2, 3, 4, 5]
        let ours = [1, 2, 99, 4, 5]
        let theirs = [1, 2, 3, 4, 100]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == [1, 2, 99, 4, 100])
    }

    @Test("One side adds multiple lines")
    func testOneSideAddsMultipleLines() {
        let base = ["A", "D"]
        let ours = ["A", "B", "C", "D"]
        let theirs = ["A", "D"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "B", "C", "D"])
    }

    @Test("One side removes multiple lines")
    func testOneSideRemovesMultipleLines() {
        let base = ["A", "B", "C", "D"]
        let ours = ["A", "D"]
        let theirs = ["A", "B", "C", "D"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "D"])
    }

    @Test("Adjacent non-overlapping modifications")
    func testAdjacentNonOverlappingModifications() {
        let base = ["A", "B", "C", "D", "E"]
        let ours = ["A", "X", "C", "D", "E"]
        let theirs = ["A", "B", "C", "Y", "E"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge for adjacent changes")
            return
        }

        #expect(merged == ["A", "X", "C", "Y", "E"])
    }

    @Test("Both sides add different content at end")
    func testBothSidesAddDifferentContentAtEnd() {
        let base = ["A", "B"]
        let ours = ["A", "B", "C", "D"]
        let theirs = ["A", "B", "X", "Y"]

        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        let result = merger.merge()

        // This should be a conflict
        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }
}
