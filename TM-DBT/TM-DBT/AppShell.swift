import AppKit
import Combine
import SwiftUI

final class AppShellState: ObservableObject {
    @Published var selectedTab: AppTab = .today
}

@main
final class TM_DBTAppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: DBTWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = DBTWindowController()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        windowController = controller
    }
}

final class DBTWindowController: NSWindowController {
    init() {
        let rootViewController = NSHostingController(rootView: ShellRootView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.hasShadow = false
        window.level = .normal
        window.contentViewController = rootViewController
        window.backgroundColor = NSColor(DBTTheme.surface)
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ShellRootView: View {
    @StateObject private var state = AppShellState()

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            tabBar
        }
        .background(DBTTheme.surface)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TM-DBT")
                    .font(.system(size: 14, weight: .semibold))
                Text("Daily DBT scaffold")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DBTTheme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(height: 72, alignment: .top)
        .background(DBTTheme.surface2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(DBTTheme.border), alignment: .bottom)
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch state.selectedTab {
            case .today:
                TodayView()
            case .diary:
                DiaryView()
            case .worksheets:
                WorksheetsView()
            case .resources:
                ResourcesView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            tabButton(.today, title: "Today", symbol: "sun.max.fill")
            tabButton(.diary, title: "Diary", symbol: "list.clipboard")
            tabButton(.worksheets, title: "Worksheets", symbol: "doc.richtext")
            tabButton(.resources, title: "Resources", symbol: "rectangle.stack")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DBTTheme.surface2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(DBTTheme.border), alignment: .top)
    }

    private func tabButton(_ tab: AppTab, title: String, symbol: String) -> some View {
        Button {
            state.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(state.selectedTab == tab ? DBTTheme.text : DBTTheme.muted)
            .background(state.selectedTab == tab ? DBTTheme.accent.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(state.selectedTab == tab ? DBTTheme.accent : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
