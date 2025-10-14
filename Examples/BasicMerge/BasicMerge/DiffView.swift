import SwiftUI
import Merge

struct DiffView: View {
    let originalFile: String
    let modifiedFile: String

    @State private var diffLines: [Line] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(diffLines) { line in
                    HStack(alignment: .top, spacing: 8) {
                        if let lineNum = line.lineNumber {
                            Text("\(lineNum)")
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        } else {
                            Text("")
                                .frame(width: 40)
                        }

                        HStack(alignment: .top, spacing: 4) {
                            Text(line.prefix)
                                .foregroundColor(line.type == .added ? .green :
                                               line.type == .removed ? .red : .primary)

                            Text(line.content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .background(line.backgroundColor)
                    .font(.system(.subheadline, design: .monospaced))
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .task(id: originalFile+modifiedFile) {
            handleCompute()
        }
    }

    func handleCompute() {
        let changes = Merge.diffStrings(original: originalFile, modified: modifiedFile)
        let lines: [Line] = changes.map {
            switch $0 {
            case let .equal(index, element):
                .init(
                    lineNumber: index + 1,
                    content: element,
                    type: .unchanged
                )
            case let .delete(index, element):
                .init(
                    lineNumber: index + 1,
                    content: element,
                    type: .removed
                )
            case let .insert(index, element):
                .init(
                    lineNumber: index + 1,
                    content: element,
                    type: .added
                )
            }
        }
        diffLines = lines
    }

    struct Line: Identifiable {
        let id = UUID()
        let lineNumber: Int?
        let content: String
        let type: LineType

        enum LineType {
            case unchanged
            case added
            case removed
        }

        var backgroundColor: Color {
            switch type {
            case .unchanged: return .clear
            case .added: return .green.opacity(0.2)
            case .removed: return .red.opacity(0.2)
            }
        }

        var prefix: String {
            switch type {
            case .unchanged: return "  "
            case .added: return "+ "
            case .removed: return "- "
            }
        }
    }
}
