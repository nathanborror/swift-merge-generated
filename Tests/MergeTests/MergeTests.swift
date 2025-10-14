import Testing

@testable import Merge

@Suite("Public API Integration Tests")
struct MergeTests {

    // MARK: - Diff API Tests

    @Test("Diff convenience API works")
    func testDiffAPI() {
        let original = ["A", "B", "C"]
        let modified = ["A", "X", "C"]

        let changes = Merge.diff(original: original, modified: modified)

        #expect(changes.count == 4)
        #expect(changes[0] == .equal(index: 0, element: "A"))
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .insert(index: 1, element: "X"))
        #expect(changes[3] == .equal(index: 2, element: "C"))
    }

    @Test("Diff strings API splits by newlines")
    func testDiffStringsAPI() {
        let original = "Hello\nWorld\n"
        let modified = "Hello\nSwift\nWorld\n"

        let changes = Merge.diffStrings(original: original, modified: modified)

        #expect(changes.count == 4)
        #expect(changes[0] == .equal(index: 0, element: "Hello"))
        #expect(changes[1] == .insert(index: 1, element: "Swift"))
        #expect(changes[2] == .equal(index: 1, element: "World"))
        #expect(changes[3] == .equal(index: 2, element: ""))
    }

    @Test("Diff strings with custom separator")
    func testDiffStringsCustomSeparator() {
        let original = "A,B,C"
        let modified = "A,X,C"

        let changes = Merge.diffStrings(original: original, modified: modified, separator: ",")

        #expect(changes.count == 4)
        #expect(changes[1] == .delete(index: 1, element: "B"))
        #expect(changes[2] == .insert(index: 1, element: "X"))
    }

    // MARK: - Three-Way Merge API Tests

    @Test("Three-way merge convenience API works")
    func testThreeWayAPI() {
        let base = ["A", "B", "C", "D"]
        let ours = ["A", "X", "C", "D"]
        let theirs = ["A", "B", "C", "Y"]

        let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == ["A", "X", "C", "Y"])
    }

    @Test("Three-way merge detects conflicts")
    func testThreeWayAPIConflict() {
        let base = ["A", "B", "C"]
        let ours = ["A", "X", "C"]
        let theirs = ["A", "Y", "C"]

        let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
        #expect(conflict.conflicts[0].base == ["B"])
        #expect(conflict.conflicts[0].ours == ["X"])
        #expect(conflict.conflicts[0].theirs == ["Y"])
    }

    // MARK: - String Merge API Tests

    @Test("String merge successful case")
    func testStringMergeSuccess() {
        let base = """
            function greet() {
              console.log("Hello");
              console.log("World");
            }
            """

        let ours = """
            function greet() {
              console.log("Hello");
              console.log("Beautiful");
              console.log("World");
            }
            """

        let theirs = """
            function greet(name) {
              console.log("Hello");
              console.log("World");
            }
            """

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        let expected = """
            function greet(name) {
              console.log("Hello");
              console.log("Beautiful");
              console.log("World");
            }
            """
        #expect(merged == expected)
    }

    @Test("String merge conflict case")
    func testStringMergeConflict() {
        let base = "Line 1\nLine 2\nLine 3\n"
        let ours = "Line 1\nOur Change\nLine 3\n"
        let theirs = "Line 1\nTheir Change\nLine 3\n"

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
        #expect(conflict.conflicts[0].base == "Line 2")
        #expect(conflict.conflicts[0].ours == "Our Change")
        #expect(conflict.conflicts[0].theirs == "Their Change")
        #expect(conflict.conflicts[0].startLine == 1)
    }

    @Test("String merge preserves newlines")
    func testStringMergePreservesNewlines() {
        let base = "A\nB\nC\n"
        let ours = "A\nX\nC\n"
        let theirs = "A\nB\nC\n"

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == "A\nX\nC\n")
    }

    @Test("String merge with empty lines")
    func testStringMergeWithEmptyLines() {
        let base = "A\n\nC\n"
        let ours = "A\nB\n\nC\n"
        let theirs = "A\n\nC\nD\n"

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == "A\nB\n\nC\nD\n")
    }

    @Test("String merge with custom separator")
    func testStringMergeCustomSeparator() {
        let base = "A|B|C"
        let ours = "A|X|C"
        let theirs = "A|B|Y"

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs, separator: "|")

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == "A|X|Y")
    }

    // MARK: - Conflict Marker Formatting Tests

    @Test("Conflict markers format correctly")
    func testConflictMarkerFormatting() {
        let conflict = StringConflictRegion(
            base: "Original",
            ours: "Our Version",
            theirs: "Their Version",
            startLine: 5
        )

        let formatted = conflict.formatAsConflictMarkers()

        #expect(formatted.contains("<<<<<<< ours"))
        #expect(formatted.contains("Our Version"))
        #expect(formatted.contains("||||||| base"))
        #expect(formatted.contains("Original"))
        #expect(formatted.contains("======="))
        #expect(formatted.contains("Their Version"))
        #expect(formatted.contains(">>>>>>> theirs"))
    }

    @Test("Conflict description is readable")
    func testConflictDescription() {
        let conflict = StringConflictRegion(
            base: "base content",
            ours: "our content",
            theirs: "their content",
            startLine: 10
        )

        let description = conflict.description

        #expect(description.contains("line 10"))
        #expect(description.contains("base content"))
        #expect(description.contains("our content"))
        #expect(description.contains("their content"))
    }

    // MARK: - Real-world Scenarios

    @Test("Merge code file with non-conflicting changes")
    func testCodeFileMerge() {
        let base = """
            import Foundation

            struct User {
                let name: String
                let age: Int
            }
            """

        let ours = """
            import Foundation

            struct User {
                let name: String
                let age: Int
                let email: String
            }
            """

        let theirs = """
            import Foundation
            import SwiftUI

            struct User {
                let name: String
                let age: Int
            }
            """

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged.contains("import SwiftUI"))
        #expect(merged.contains("let email: String"))
    }

    @Test("Merge configuration file")
    func testConfigFileMerge() {
        let base = """
            {
                "version": "1.0",
                "debug": false
            }
            """

        let ours = """
            {
                "version": "1.1",
                "debug": false
            }
            """

        let theirs = """
            {
                "version": "1.0",
                "debug": true
            }
            """

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged.contains("1.1"))
        #expect(merged.contains("true"))
    }

    @Test("Merge with one side making no changes")
    func testMergeWithOneSideUnchanged() {
        let base = "A\nB\nC\n"
        let ours = "A\nB\nC\nD\n"
        let theirs = base

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == "A\nB\nC\nD\n")
    }

    @Test("Merge empty files")
    func testMergeEmptyFiles() {
        let base = ""
        let ours = ""
        let theirs = ""

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged == "")
    }

    @Test("Merge when both sides add to empty base")
    func testMergeBothAddToEmptyBase() {
        let base = ""
        let ours = "Our content\n"
        let theirs = "Their content\n"

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .conflict(let conflict) = result else {
            Issue.record("Expected conflict")
            return
        }

        #expect(conflict.conflicts.count == 1)
    }

    @Test("Merge documentation with different additions")
    func testMergeDocumentation() {
        let base = """
            # MyProject

            A simple project.
            """

        let ours = """
            # MyProject

            A simple project.

            ## Installation
            Run `swift build`
            """

        let theirs = """
            # MyProject

            A simple project.

            ## Features
            - Fast
            - Reliable
            """

        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        guard case .success(let merged) = result else {
            Issue.record("Expected successful merge")
            return
        }

        #expect(merged.contains("Installation"))
        #expect(merged.contains("Features"))
    }
}
