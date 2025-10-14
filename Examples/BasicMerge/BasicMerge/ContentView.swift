import SwiftUI
import Merge

struct ContentView: View {
    @State var originalCode = """
    import Foundation
    
    struct User {
        let name: String
        let age: Int
    }
    """

    @State var modifiedCode = """
    import SwiftUI
    
    struct User {
        let name: String
        let email: String
        let age: Int
    }
    """

    var body: some View {
        VSplitView {
            HSplitView {
                TextEditor(text: $originalCode)
                    .frame(minWidth: 100)
                    .padding(8)
                TextEditor(text: $modifiedCode)
                    .frame(minWidth: 100)
                    .padding(8)
            }
            .frame(minHeight: 100)
            .font(.system(.subheadline, design: .monospaced))

            ScrollView {
                DiffView(
                    originalFile: originalCode,
                    modifiedFile: modifiedCode
                )
            }
        }
    }
}
