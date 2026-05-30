import AppKit
import SwiftUI
import os.log

enum StartupTrace {
    static let fileURL = URL(fileURLWithPath: "/tmp/TM-DBT-startup.log")

    static func write(_ line: String) {
        do {
            let data = "\(line)\n".data(using: .utf8) ?? Data()
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: fileURL, options: [.atomic])
            }
        } catch {
            print("startup_trace_write_failed \(error)")
        }
    }
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
        let rootViewController = DBTRootViewController()
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

final class DBTRootViewController: NSViewController {
    private let segmentedControl = NSSegmentedControl(labels: ["Today", "Diary", "Worksheets", "Resources"], trackingMode: .selectOne, target: nil, action: nil)
    private let contentContainer = NSView()
    private var currentHost: NSViewController?
    private var hostCache: [AppTab: NSViewController] = [:]
    private var selectedTab: AppTab = .today
    private let loadingLabel = NSTextField(labelWithString: "Ready")
    private let logger = Logger(subsystem: "com.techmore.org.TM-DBT", category: "startup")

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(DBTTheme.surface).cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        StartupTrace.write("root_view_did_load")
        configureHeader()
        configureContentContainer()
        showPlaceholder()
    }

    private func configureHeader() {
        segmentedControl.segmentStyle = .rounded
        segmentedControl.selectedSegment = 0
        segmentedControl.target = self
        segmentedControl.action = #selector(tabChanged(_:))

        let bar = NSView()
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor(DBTTheme.surface2).cgColor
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
        loadingLabel.font = .systemFont(ofSize: 13, weight: .medium)
        loadingLabel.textColor = .secondaryLabelColor
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        contentContainer.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 72),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor)
        ])
    }

    private func showPlaceholder() {
        loadingLabel.stringValue = "Select a tab"
    }

    private func activate(tab: AppTab) {
        let host = hostCache[tab] ?? buildHost(for: tab)
        currentHost = host
        ensureAttached(host)
        hideAllHosts(except: host)
    }

    @objc private func tabChanged(_ sender: NSSegmentedControl) {
        let newTab: AppTab
        switch sender.selectedSegment {
        case 0: newTab = .today
        case 1: newTab = .diary
        case 2: newTab = .worksheets
        default: newTab = .resources
        }
        self.logger.info("tab_selected tab=\(self.tabName(newTab), privacy: .public)")
        updateContent(for: newTab)
    }

    private func updateContent(for tab: AppTab) {
        guard tab != selectedTab || currentHost == nil else { return }
        selectedTab = tab
        let start = CACurrentMediaTime()
        self.logger.info("tab_content_update_start tab=\(self.tabName(tab), privacy: .public)")

        loadingLabel.stringValue = "Loading..."

        if let cachedHost = hostCache[tab] {
            ensureAttached(cachedHost)
            hideAllHosts(except: cachedHost)
            loadingLabel.stringValue = "Ready"
            currentHost = cachedHost
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let host = self.hostCache[tab] ?? self.buildHost(for: tab)
            self.ensureAttached(host)
            self.hideAllHosts(except: host)
            self.loadingLabel.stringValue = "Ready"
            self.currentHost = host
            let duration = Int((CACurrentMediaTime() - start) * 1000)
            StartupTrace.write("tab_host_built tab=\(self.tabName(tab)) duration_ms=\(duration)")
            self.logger.info("tab_host_built tab=\(self.tabName(tab), privacy: .public) duration_ms=\(duration, privacy: .public)")
        }
    }

    private func buildHost(for tab: AppTab) -> NSViewController {
        let host: NSViewController
        switch tab {
        case .today:
            host = NSHostingController(rootView: TodayView())
        case .diary:
            host = NSHostingController(rootView: DiaryView())
        case .worksheets:
            host = NSHostingController(rootView: WorksheetsView())
        case .resources:
            host = NSHostingController(rootView: ResourcesView())
        }
        hostCache[tab] = host
        return host
    }

    private func ensureAttached(_ host: NSViewController) {
        guard host.view.superview == nil else { return }
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.isHidden = true
        contentContainer.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }

    private func hideAllHosts(except visibleHost: NSViewController) {
        for host in hostCache.values {
            host.view.isHidden = host !== visibleHost
        }
    }

    private func tabName(_ tab: AppTab) -> String {
        switch tab {
        case .today: return "today"
        case .diary: return "diary"
        case .worksheets: return "worksheets"
        case .resources: return "resources"
        }
    }
}
