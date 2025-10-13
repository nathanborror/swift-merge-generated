/// A Swift package for performing three-way merges using Myers' diff algorithm.
///
/// This package provides functionality to merge two divergent versions of content
/// by using their common ancestor as a reference point.
///
/// ## Usage
///
/// ### Basic Three-Way Merge
///
/// ```swift
/// let base = ["A", "B", "C", "D"]
/// let ours = ["A", "B", "X", "D"]
/// let theirs = ["A", "Y", "C", "D"]
///
/// let result = Merge.threeWay(base: base, ours: ours, theirs: theirs)
/// switch result {
/// case .success(let merged):
///     print("Merged:", merged)
/// case .conflict(let conflict):
///     print("Conflict detected!")
/// }
/// ```
///
/// ### String Merging
///
/// ```swift
/// let base = "Hello\nWorld\n"
/// let ours = "Hello\nSwift\nWorld\n"
/// let theirs = "Hi\nWorld\n"
///
/// let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)
/// ```
///
/// ### Computing Diffs
///
/// ```swift
/// let original = ["A", "B", "C"]
/// let modified = ["A", "X", "C"]
///
/// let changes = Merge.diff(original: original, modified: modified)
/// for change in changes {
///     print(change)
/// }
/// ```
public enum Merge {

    /// Performs a three-way merge on sequences of equatable elements.
    ///
    /// - Parameters:
    ///   - base: The common ancestor sequence
    ///   - ours: The local changes
    ///   - theirs: The remote changes
    /// - Returns: The merge result, either success or conflict
    public static func threeWay<Element: Equatable>(
        base: [Element],
        ours: [Element],
        theirs: [Element]
    ) -> ThreeWayMerge<Element>.MergeResult {
        let merger = ThreeWayMerge(base: base, ours: ours, theirs: theirs)
        return merger.merge()
    }

    /// Performs a three-way merge on strings by splitting them into lines.
    ///
    /// This is a convenience method for the common case of merging text files.
    /// Lines are split on newline characters and preserved in the output.
    ///
    /// - Parameters:
    ///   - base: The common ancestor string
    ///   - ours: The local changes
    ///   - theirs: The remote changes
    ///   - separator: The line separator to use (default: "\n")
    /// - Returns: The merge result as a string result
    public static func threeWayStrings(
        base: String,
        ours: String,
        theirs: String,
        separator: String = "\n"
    ) -> StringMergeResult {
        let baseLines = base.split(separator: separator, omittingEmptySubsequences: false)
            .map(String.init)
        let ourLines = ours.split(separator: separator, omittingEmptySubsequences: false)
            .map(String.init)
        let theirLines = theirs.split(separator: separator, omittingEmptySubsequences: false)
            .map(String.init)

        let result = threeWay(base: baseLines, ours: ourLines, theirs: theirLines)

        switch result {
        case .success(let lines):
            return .success(lines.joined(separator: separator))
        case .conflict(let conflict):
            return .conflict(
                StringMergeConflict(
                    partial: conflict.partial.joined(separator: separator),
                    conflicts: conflict.conflicts.map { region in
                        StringConflictRegion(
                            base: region.base.joined(separator: separator),
                            ours: region.ours.joined(separator: separator),
                            theirs: region.theirs.joined(separator: separator),
                            startLine: region.startIndex
                        )
                    }
                ))
        }
    }

    /// Computes the differences between two sequences using Myers' diff algorithm.
    ///
    /// - Parameters:
    ///   - original: The original sequence
    ///   - modified: The modified sequence
    /// - Returns: An array of changes representing the edit script
    public static func diff<Element: Equatable>(
        original: [Element],
        modified: [Element]
    ) -> [MyersDiff<Element>.Change] {
        let differ = MyersDiff(original: original, modified: modified)
        return differ.diff()
    }

    /// Computes the differences between two strings by splitting them into lines.
    ///
    /// - Parameters:
    ///   - original: The original string
    ///   - modified: The modified string
    ///   - separator: The line separator to use (default: "\n")
    /// - Returns: An array of changes representing the edit script
    public static func diffStrings(
        original: String,
        modified: String,
        separator: String = "\n"
    ) -> [MyersDiff<String>.Change] {
        let originalLines = original.split(separator: separator, omittingEmptySubsequences: false)
            .map(String.init)
        let modifiedLines = modified.split(separator: separator, omittingEmptySubsequences: false)
            .map(String.init)

        return diff(original: originalLines, modified: modifiedLines)
    }
}

// MARK: - String Merge Results

/// Result of a string-based three-way merge
public enum StringMergeResult {
    /// The merge completed successfully
    case success(String)
    /// The merge encountered conflicts
    case conflict(StringMergeConflict)
}

/// Information about conflicts in a string merge
public struct StringMergeConflict {
    /// The merged result up to the point of conflict
    public let partial: String
    /// Conflicting regions
    public let conflicts: [StringConflictRegion]

    public init(partial: String, conflicts: [StringConflictRegion]) {
        self.partial = partial
        self.conflicts = conflicts
    }
}

/// A single conflicting region in a string merge
public struct StringConflictRegion {
    /// Content from the base version
    public let base: String
    /// Content from our version
    public let ours: String
    /// Content from their version
    public let theirs: String
    /// The line number where the conflict starts
    public let startLine: Int

    public init(base: String, ours: String, theirs: String, startLine: Int) {
        self.base = base
        self.ours = ours
        self.theirs = theirs
        self.startLine = startLine
    }

    /// Formats the conflict in standard diff3 format
    public func formatAsConflictMarkers(separator: String = "\n") -> String {
        """
        <<<<<<< ours\(separator)\
        \(ours)\(separator)\
        ||||||| base\(separator)\
        \(base)\(separator)\
        =======\(separator)\
        \(theirs)\(separator)\
        >>>>>>> theirs
        """
    }
}

extension StringConflictRegion: CustomStringConvertible {
    public var description: String {
        """
        Conflict at line \(startLine):
          Base: "\(base)"
          Ours: "\(ours)"
          Theirs: "\(theirs)"
        """
    }
}
