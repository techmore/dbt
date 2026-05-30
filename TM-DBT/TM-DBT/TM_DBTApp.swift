import SwiftUI

@main
struct TM_DBTApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchShellView()
                .frame(minWidth: 1180, minHeight: 820)
        }
    }
}

private struct LaunchShellView: View {
    @State private var showContent = false

    var body: some View {
        Group {
            if showContent {
                ContentView()
            } else {
                launchPlaceholder
            }
        }
        .background(DBTTheme.surface)
    }

    private var launchPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TM-DBT")
                .font(.headline)
                .foregroundStyle(DBTTheme.text)
            Text("Start light. Open the scaffold when you are ready.")
                .font(.subheadline)
                .foregroundStyle(DBTTheme.muted)
            Button("Open scaffold") {
                showContent = true
            }
            .buttonStyle(.borderedProminent)
            .tint(DBTTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }
}
