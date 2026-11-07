import SwiftUI

@main
struct TM_DBTApp: App {
    @State private var store = PracticeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(DBTTheme.accent)
                #if os(macOS)
                .frame(minWidth: 720, minHeight: 600)
                #endif
        }
    }
}
