import SwiftUI

@main
struct MainApp: App {

    @State var selection = Selection.merge

    enum Selection {
        case diff
        case merge
    }

    var body: some Scene {
        WindowGroup("Merge Examples") {
            NavigationSplitView {
                List(selection: $selection) {
                    Text("Diff").tag(Selection.diff)
                    Text("Merge").tag(Selection.merge)
                }
            } detail: {
                switch selection {
                case .diff:
                    DiffExample()
                case .merge:
                    MergeExample()
                }
            }
        }
    }
}

struct HeadingModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(.quinary)
    }
}

struct ContentModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .monospaced))
            .padding(8)
    }
}
