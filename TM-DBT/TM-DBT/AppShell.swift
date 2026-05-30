import AppKit
import SwiftUI

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
        let rootViewController = DBTRootViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TM-DBT"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = rootViewController
        window.backgroundColor = NSColor(DBTTheme.surface)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DBTRootViewController: NSViewController {
    private let segmentedControl = NSSegmentedControl(labels: ["Today", "Diary", "Worksheets", "Resources"], trackingMode: .selectOne, target: nil, action: nil)
    private let contentContainer = NSView()
    private var currentHost: NSViewController?
    private var selectedTab: AppTab = .today

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(DBTTheme.surface).cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHeader()
        configureContentContainer()
        updateContent(for: .today)
    }

    private func configureHeader() {
        segmentedControl.segmentStyle = .rounded
        segmentedControl.selectedSegment = 0
        segmentedControl.target = self
        segmentedControl.action = #selector(tabChanged(_:))

        let bar = NSVisualEffectView()
        bar.material = .hudWindow
        bar.state = .active
        bar.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "TM-DBT")
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = NSTextField(labelWithString: "Daily DBT scaffold")
        subtitle.font = .systemFont(ofSize: 11, weight: .medium)
        subtitle.textColor = .secondaryLabelColor
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bar)
        bar.addSubview(title)
        bar.addSubview(subtitle)
        bar.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 72),

            title.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 18),
            title.topAnchor.constraint(equalTo: bar.topAnchor, constant: 12),

            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),

            segmentedControl.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -18),
            segmentedControl.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
        ])
    }

    private func configureContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.wantsLayer = true
        contentContainer.layer?.backgroundColor = NSColor(DBTTheme.surface).cgColor
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 72),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func tabChanged(_ sender: NSSegmentedControl) {
        let newTab: AppTab
        switch sender.selectedSegment {
        case 0: newTab = .today
        case 1: newTab = .diary
        case 2: newTab = .worksheets
        default: newTab = .resources
        }
        updateContent(for: newTab)
    }

    private func updateContent(for tab: AppTab) {
        guard tab != selectedTab || currentHost == nil else { return }
        selectedTab = tab

        currentHost?.view.removeFromSuperview()
        currentHost?.removeFromParent()

        let host = NSHostingController(rootView: rootView(for: tab))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        currentHost = host
    }

    private func rootView(for tab: AppTab) -> AnyView {
        switch tab {
        case .today:
            AnyView(TodayView())
        case .diary:
            AnyView(DiaryView())
        case .worksheets:
            AnyView(WorksheetsView())
        case .resources:
            AnyView(ResourcesView())
        }
    }
}
