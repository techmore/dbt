import AppKit
import SwiftUI

@main
final class TM_DBTAppDelegate: NSObject, NSApplicationDelegate {
    private var shell: DBTWindowShell?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let shell = DBTWindowShell()
        shell.show()
        self.shell = shell
    }
}

final class DBTWindowShell: NSObject {
    private let window: NSWindow
    private let rootView = NSView()
    private let headerView = NSView()
    private let contentContainer = NSView()
    private let tabBar = NSStackView()
    private let buttonStack = NSStackView()
    private let titleLabel = NSTextField(labelWithString: "TM-DBT")
    private let subtitleLabel = NSTextField(labelWithString: "Daily DBT scaffold")
    private var contentHost: NSHostingView<TabContentHostView>?
    private var selectedTab: AppTab?
    private let tabs: [AppTab] = [.today, .diary, .worksheets, .resources]

    private lazy var tabButtons: [AppTab: NSButton] = [
        .today: makeTabButton(title: "Today", symbol: "sun.max.fill", tab: .today),
        .diary: makeTabButton(title: "Diary", symbol: "list.clipboard", tab: .diary),
        .worksheets: makeTabButton(title: "Worksheets", symbol: "doc.richtext", tab: .worksheets),
        .resources: makeTabButton(title: "Resources", symbol: "rectangle.stack", tab: .resources)
    ]

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        configureWindow()
        buildShell()
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow() {
        window.title = "TM-DBT"
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.hasShadow = true
        window.level = .normal
        window.backgroundColor = NSColor(DBTTheme.surface)
        window.contentView = rootView
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor(DBTTheme.surface).cgColor
    }

    private func buildShell() {
        setupHeader()
        setupContent()
        setupTabBar()

        let stack = NSStackView(views: [headerView, contentContainer, tabBar])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        rootView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: rootView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 72),
            tabBar.heightAnchor.constraint(equalToConstant: 60),
            contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }

    private func setupHeader() {
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = NSColor(DBTTheme.text)
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = NSColor(DBTTheme.muted)

        let stack = NSStackView(views: [titleLabel, subtitleLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2

        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor(DBTTheme.surface2).cgColor
        headerView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 18),
            stack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor, constant: -10),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -18)
        ])

        let border = NSView()
        border.wantsLayer = true
        border.layer?.backgroundColor = NSColor(DBTTheme.border).cgColor
        headerView.addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            border.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupContent() {
        contentContainer.wantsLayer = true
        contentContainer.layer?.backgroundColor = NSColor(DBTTheme.surface).cgColor

        let label = NSTextField(labelWithString: "Select a tab to open the scaffold.")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = NSColor(DBTTheme.text)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 16)
        ])
    }

    private func setupTabBar() {
        tabBar.orientation = .horizontal
        tabBar.alignment = .centerY
        tabBar.distribution = .fillEqually
        tabBar.spacing = 10
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        tabs.forEach { tab in
            if let button = tabButtons[tab] {
                buttonStack.addArrangedSubview(button)
            }
        }

        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 10

        tabBar.addArrangedSubview(buttonStack)
        tabBar.setHuggingPriority(.required, for: .vertical)
        tabBar.wantsLayer = true
        tabBar.layer?.backgroundColor = NSColor(DBTTheme.surface2).cgColor

        let border = NSView()
        border.wantsLayer = true
        border.layer?.backgroundColor = NSColor(DBTTheme.border).cgColor
        tabBar.addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            border.topAnchor.constraint(equalTo: tabBar.topAnchor),
            border.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func makeTabButton(title: String, symbol: String, tab: AppTab) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(tabSelected(_:)))
        button.tag = tab.tag
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.contentTintColor = NSColor(DBTTheme.muted)
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        button.imagePosition = .imageAbove
        button.imageScaling = .scaleProportionallyDown
        button.font = .systemFont(ofSize: 11, weight: .semibold)
        button.wantsLayer = true
        button.layer?.cornerRadius = 10
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.clear.cgColor
        button.layer?.backgroundColor = NSColor.clear.cgColor
        return button
    }

    @objc private func tabSelected(_ sender: NSButton) {
        guard let tab = AppTab(tag: sender.tag) else { return }
        selectedTab = tab
        updateTabButtonStyles()
        showTab(tab)
    }

    private func showTab(_ tab: AppTab) {
        if contentHost == nil {
            let host = NSHostingView(rootView: TabContentHostView(renderedTab: tab))
            contentHost = host
            contentContainer.subviews.forEach { $0.removeFromSuperview() }
            contentContainer.addSubview(host)
            host.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                host.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                host.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
            ])
        } else {
            contentHost?.rootView = TabContentHostView(renderedTab: tab)
        }
    }

    private func updateTabButtonStyles() {
        for tab in tabs {
            guard let button = tabButtons[tab] else { continue }
            let active = selectedTab == tab
            button.contentTintColor = active ? NSColor(DBTTheme.text) : NSColor(DBTTheme.muted)
            button.layer?.borderColor = active ? NSColor(DBTTheme.accent).cgColor : NSColor.clear.cgColor
            button.layer?.backgroundColor = active ? NSColor(DBTTheme.accent).withAlphaComponent(0.18).cgColor : NSColor.clear.cgColor
        }
    }
}

private struct TabContentHostView: View {
    var renderedTab: AppTab?

    var body: some View {
        Group {
            switch renderedTab {
            case .today:
                TodayView()
            case .diary:
                DiaryView()
            case .worksheets:
                WorksheetsView()
            case .resources:
                ResourcesView()
            case nil:
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a tab to open the scaffold.")
                .foregroundStyle(DBTTheme.text)
        }
        .padding(16)
    }
}

private extension AppTab {
    var tag: Int {
        switch self {
        case .today: return 0
        case .diary: return 1
        case .worksheets: return 2
        case .resources: return 3
        }
    }

    init?(tag: Int) {
        switch tag {
        case 0: self = .today
        case 1: self = .diary
        case 2: self = .worksheets
        case 3: self = .resources
        default: return nil
        }
    }
}
