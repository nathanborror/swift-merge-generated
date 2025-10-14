import Merge
import SwiftUI

struct MergeExample: View {
    @State var base = """
        import Foundation

        struct User {
            let name: String
            let age: Int
            let email: String
        }

        func greet() {
            print("Hello")
        }
        """

    @State var ours = """
        import Foundation

        struct User {
            let name: String
            let age: Int
            let email: String
            let phone: String
        }

        func greet() {
            print("Hello, User!")
        }
        """

    @State var theirs = """
        import Foundation

        struct User {
            let name: String
            let age: Int
            let email: String
            let address: String
        }

        func greet() {
            print("Hi there!")
        }
        """

    var body: some View {
        VSplitView {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("Base")
                        .modifier(HeadingModifier())
                    TextEditor(text: $base)
                        .modifier(ContentModifier())
                }

                Divider()

                VStack(spacing: 0) {
                    Text("Ours")
                        .modifier(HeadingModifier())
                    TextEditor(text: $ours)
                        .modifier(ContentModifier())
                }

                Divider()

                VStack(spacing: 0) {
                    Text("Theirs")
                        .modifier(HeadingModifier())
                    TextEditor(text: $theirs)
                        .modifier(ContentModifier())
                }
            }
            .frame(minHeight: 100, idealHeight: 200)

            MergeResultView(base: base, ours: ours, theirs: theirs)
        }
    }
}

struct MergeResultView: View {
    let base: String
    let ours: String
    let theirs: String

    @State private var lines: [Line] = []
    @State private var hasConflicts = false

    var body: some View {
        VStack(spacing: 0) {
            Text(hasConflicts ? "Merge Result (Conflicts Detected)" : "Merge Result (Success)")
                .modifier(HeadingModifier())
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        HStack(alignment: .top, spacing: 8) {
                            // Line number
                            if let lineNum = line.lineNumber {
                                Text("\(lineNum)")
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            } else {
                                Text("")
                                    .frame(width: 40)
                            }

                            // Content
                            HStack(alignment: .top, spacing: 4) {
                                Text(line.prefix)
                                    .foregroundColor(line.prefixColor)
                                    .bold(line.isConflictMarker)

                                Text(line.content)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(line.textColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                        .background(line.backgroundColor)
                    }
                }
            }
            .font(.system(.subheadline, design: .monospaced))
        }
        .task(id: base + ours + theirs) {
            handleMerge()
        }
    }

    func handleMerge() {
        let result = Merge.threeWayStrings(base: base, ours: ours, theirs: theirs)

        switch result {
        case .success(let merged):
            hasConflicts = false
            let lines = merged.split(separator: "\n", omittingEmptySubsequences: false)
            self.lines = lines.enumerated().map { index, line in
                Line(
                    lineNumber: index + 1,
                    content: String(line),
                    type: .normal
                )
            }

        case .conflict(let conflict):
            hasConflicts = true
            var lines: [Line] = []
            var currentLine = 1

            // Add partial merged content before conflicts
            let partialLines = conflict.partial.split(
                separator: "\n", omittingEmptySubsequences: false)
            for line in partialLines {
                lines.append(
                    .init(
                        lineNumber: currentLine,
                        content: String(line),
                        type: .normal
                    ))
                currentLine += 1
            }

            // Add conflict regions
            for conflictRegion in conflict.conflicts {
                // Conflict start marker
                lines.append(
                    .init(
                        lineNumber: nil,
                        content: "<<<<<<< ours",
                        type: .conflictMarker
                    ))

                // Ours section
                let ourLines = conflictRegion.ours.split(
                    separator: "\n", omittingEmptySubsequences: false)
                for line in ourLines {
                    lines.append(
                        .init(
                            lineNumber: currentLine,
                            content: String(line),
                            type: .ours
                        ))
                    currentLine += 1
                }

                // Base marker
                lines.append(
                    .init(
                        lineNumber: nil,
                        content: "||||||| base",
                        type: .conflictMarker
                    ))

                // Base section
                let baseLines = conflictRegion.base.split(
                    separator: "\n", omittingEmptySubsequences: false)
                for line in baseLines {
                    lines.append(
                        .init(
                            lineNumber: nil,
                            content: String(line),
                            type: .base
                        ))
                }

                // Separator
                lines.append(
                    .init(
                        lineNumber: nil,
                        content: "=======",
                        type: .conflictMarker
                    ))

                // Theirs section
                let theirLines = conflictRegion.theirs.split(
                    separator: "\n", omittingEmptySubsequences: false)
                for line in theirLines {
                    lines.append(
                        .init(
                            lineNumber: currentLine,
                            content: String(line),
                            type: .theirs
                        ))
                    currentLine += 1
                }

                // Conflict end marker
                lines.append(
                    .init(
                        lineNumber: nil,
                        content: ">>>>>>> theirs",
                        type: .conflictMarker
                    ))
            }

            self.lines = lines
        }
    }

    struct Line: Identifiable {
        let id = UUID()
        let lineNumber: Int?
        let content: String
        let type: LineType

        enum LineType {
            case normal
            case ours
            case base
            case theirs
            case conflictMarker
        }

        var backgroundColor: Color {
            switch type {
            case .normal: return .clear
            case .ours: return .blue.opacity(0.15)
            case .base: return .gray.opacity(0.1)
            case .theirs: return .green.opacity(0.15)
            case .conflictMarker: return .red.opacity(0.2)
            }
        }

        var prefix: String {
            switch type {
            case .normal: return "  "
            case .ours: return "< "
            case .base: return "| "
            case .theirs: return "> "
            case .conflictMarker: return "! "
            }
        }

        var prefixColor: Color {
            switch type {
            case .normal: return .primary
            case .ours: return .blue
            case .base: return .secondary
            case .theirs: return .green
            case .conflictMarker: return .red
            }
        }

        var textColor: Color {
            switch type {
            case .conflictMarker: return .red
            default: return .primary
            }
        }

        var isConflictMarker: Bool {
            type == .conflictMarker
        }
    }
}
