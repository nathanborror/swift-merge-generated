import SwiftUI

@main
struct MainApp: App {
    var body: some Scene {
        WindowGroup("Merge Examples") {
                    DiffExample()
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
