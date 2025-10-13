/// Three-way merge implementation using Myers' diff algorithm.
///
/// This algorithm merges two divergent sequences by using their common ancestor (base).
/// It computes changes from the base to each variant and attempts to combine them,
/// detecting conflicts when both variants modify the same region.
public struct ThreeWayMerge<Element: Equatable> {

    /// Represents the result of a merge operation
    public enum MergeResult {
        /// The merge completed successfully without conflicts
        case success([Element])
        /// The merge encountered conflicts
        case conflict(MergeConflict)
    }

    /// Represents a conflict during merge with information about both sides
    public struct MergeConflict {
        /// The merged result up to the point of conflict
        public let partial: [Element]
        /// Conflicting regions
        public let conflicts: [ConflictRegion]

        public init(partial: [Element], conflicts: [ConflictRegion]) {
            self.partial = partial
            self.conflicts = conflicts
        }
    }

    /// Represents a single conflicting region
    public struct ConflictRegion {
        /// Elements from the base version
        public let base: [Element]
        /// Elements from our version
        public let ours: [Element]
        /// Elements from their version
        public let theirs: [Element]
        /// The line number where the conflict starts
        public let startIndex: Int

        public init(base: [Element], ours: [Element], theirs: [Element], startIndex: Int) {
            self.base = base
            self.ours = ours
            self.theirs = theirs
            self.startIndex = startIndex
        }
    }

    private let base: [Element]
    private let ours: [Element]
    private let theirs: [Element]

    /// Creates a new three-way merge instance
    /// - Parameters:
    ///   - base: The common ancestor sequence
    ///   - ours: The local changes
    ///   - theirs: The remote changes
    public init(base: [Element], ours: [Element], theirs: [Element]) {
        self.base = base
        self.ours = ours
        self.theirs = theirs
    }

    /// Performs the three-way merge
    /// - Returns: The merge result, either success with merged content or conflict information
    public func merge() -> MergeResult {
        // Special case: if all three are identical, no merge needed
        if base == ours && base == theirs {
            return .success(base)
        }

        // Special case: if ours equals base, use theirs
        if base == ours {
            return .success(theirs)
        }

        // Special case: if theirs equals base, use ours
        if base == theirs {
            return .success(ours)
        }

        // Special case: if ours and theirs are identical, use either
        if ours == theirs {
            return .success(ours)
        }

        // Compute diffs from base to each variant
        let oursDiff = MyersDiff(original: base, modified: ours).diff()
        let theirsDiff = MyersDiff(original: base, modified: theirs).diff()

        // Build edit scripts
        let ourEdits = buildEditScript(from: oursDiff, modified: ours)
        let theirEdits = buildEditScript(from: theirsDiff, modified: theirs)

        // Perform the merge
        return performMerge(ourEdits: ourEdits, theirEdits: theirEdits)
    }

    /// Represents an edit operation on a range of base elements
    private struct Edit {
        let baseStart: Int  // Starting index in base
        let baseCount: Int  // Number of elements in base affected
        let replacement: [Element]  // Replacement elements
    }

    /// Builds an edit script from diff changes
    private func buildEditScript(from changes: [MyersDiff<Element>.Change], modified: [Element])
        -> [Edit]
    {
        var edits: [Edit] = []
        var i = 0
        var basePos = 0

        while i < changes.count {
            switch changes[i] {
            case .equal(let idx, _):
                basePos = idx + 1
                i += 1

            case .delete, .insert:
                // Collect a group of changes
                var deleteIndices: [Int] = []
                var insertElements: [Element] = []

                while i < changes.count {
                    switch changes[i] {
                    case .delete(let idx, _):
                        deleteIndices.append(idx)
                        i += 1
                    case .insert(_, let elem):
                        insertElements.append(elem)
                        i += 1
                    case .equal:
                        break
                    }

                    if i < changes.count, case .equal = changes[i] {
                        break
                    }
                }

                // Create edit for this change group
                if !deleteIndices.isEmpty || !insertElements.isEmpty {
                    let start = deleteIndices.first ?? basePos
                    let count = deleteIndices.count
                    edits.append(
                        Edit(baseStart: start, baseCount: count, replacement: insertElements))
                    if !deleteIndices.isEmpty {
                        basePos = deleteIndices.max()! + 1
                    }
                }
            }
        }

        return edits
    }

    /// Performs the actual merge using edit scripts
    private func performMerge(ourEdits: [Edit], theirEdits: [Edit]) -> MergeResult {
        var result: [Element] = []
        var conflicts: [ConflictRegion] = []

        var ourIdx = 0
        var theirIdx = 0
        var basePos = 0

        while basePos < base.count || ourIdx < ourEdits.count || theirIdx < theirEdits.count {
            let ourEdit = ourIdx < ourEdits.count ? ourEdits[ourIdx] : nil
            let theirEdit = theirIdx < theirEdits.count ? theirEdits[theirIdx] : nil

            if let our = ourEdit, let their = theirEdit {
                // Determine which edit comes first
                if our.baseStart < basePos {
                    ourIdx += 1
                    continue
                }
                if their.baseStart < basePos {
                    theirIdx += 1
                    continue
                }

                // Copy unchanged base content before edits
                if our.baseStart < their.baseStart {
                    result.append(contentsOf: base[basePos..<our.baseStart])
                    basePos = our.baseStart
                } else if their.baseStart < our.baseStart {
                    result.append(contentsOf: base[basePos..<their.baseStart])
                    basePos = their.baseStart
                } else {
                    // Same starting position
                    result.append(contentsOf: base[basePos..<our.baseStart])
                    basePos = our.baseStart
                }

                // Check if edits overlap
                let ourEnd = our.baseStart + our.baseCount
                let theirEnd = their.baseStart + their.baseCount

                if our.baseStart < theirEnd && their.baseStart < ourEnd {
                    // Overlapping edits - check for conflict
                    if our.baseStart == their.baseStart && our.baseCount == their.baseCount
                        && our.replacement == their.replacement
                    {
                        // Identical change - not a conflict
                        result.append(contentsOf: our.replacement)
                        basePos = max(ourEnd, theirEnd)
                        ourIdx += 1
                        theirIdx += 1
                    } else {
                        // Real conflict
                        let conflictStart = min(our.baseStart, their.baseStart)
                        let conflictEnd = max(ourEnd, theirEnd)
                        let baseContent = Array(base[conflictStart..<min(conflictEnd, base.count)])

                        conflicts.append(
                            ConflictRegion(
                                base: baseContent,
                                ours: our.replacement,
                                theirs: their.replacement,
                                startIndex: result.count
                            ))

                        basePos = conflictEnd
                        ourIdx += 1
                        theirIdx += 1
                    }
                } else if our.baseStart < their.baseStart {
                    // Our edit comes first
                    result.append(contentsOf: our.replacement)
                    basePos = ourEnd
                    ourIdx += 1
                } else {
                    // Their edit comes first
                    result.append(contentsOf: their.replacement)
                    basePos = theirEnd
                    theirIdx += 1
                }
            } else if let our = ourEdit {
                if our.baseStart < basePos {
                    ourIdx += 1
                    continue
                }
                // Only our edits remain
                result.append(contentsOf: base[basePos..<our.baseStart])
                result.append(contentsOf: our.replacement)
                basePos = our.baseStart + our.baseCount
                ourIdx += 1
            } else if let their = theirEdit {
                if their.baseStart < basePos {
                    theirIdx += 1
                    continue
                }
                // Only their edits remain
                result.append(contentsOf: base[basePos..<their.baseStart])
                result.append(contentsOf: their.replacement)
                basePos = their.baseStart + their.baseCount
                theirIdx += 1
            } else {
                // No more edits - copy rest of base
                if basePos < base.count {
                    result.append(contentsOf: base[basePos..<base.count])
                }
                basePos = base.count
            }
        }

        // Copy any remaining base content
        if basePos < base.count {
            result.append(contentsOf: base[basePos..<base.count])
        }

        if conflicts.isEmpty {
            return .success(result)
        } else {
            return .conflict(MergeConflict(partial: result, conflicts: conflicts))
        }
    }
}

extension ThreeWayMerge.ConflictRegion: CustomStringConvertible {
    public var description: String {
        """
        Conflict at index \(startIndex):
          Base: \(base)
          Ours: \(ours)
          Theirs: \(theirs)
        """
    }
}
