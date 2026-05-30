import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
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

            tabBar
                .frame(maxWidth: .infinity)
                .background(DBTTheme.surface2)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(DBTTheme.border), alignment: .top)
        }
        .background(DBTTheme.surface)
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
    }

    private func tabButton(_ tab: AppTab, title: String, symbol: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(selectedTab == tab ? DBTTheme.text : DBTTheme.muted)
            .background(selectedTab == tab ? DBTTheme.accent.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selectedTab == tab ? DBTTheme.accent : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct TodayView: View {
    @State private var showChainReview = false

    private let calendar = Calendar.current

    private enum WeekPhase: String {
        case earlyWeek = "Early week"
        case midweek = "Midweek"
        case lateWeek = "Late week"
        case weekend = "Weekend"

        var title: String { rawValue }

        var guidance: String {
            switch self {
            case .earlyWeek:
                return "Set the pace, define the target, and start clean."
            case .midweek:
                return "Protect focus, do not drift, and keep the system active."
            case .lateWeek:
                return "Catch up, review, adjust, and finish strong."
            case .weekend:
                return "Maintain structure and do not drop the routine."
            }
        }
    }

    private var weekPhase: WeekPhase {
        switch calendar.component(.weekday, from: Date()) {
        case 1, 7:
            return .weekend
        case 2, 3:
            return .earlyWeek
        case 4, 5:
            return .midweek
        default:
            return .lateWeek
        }
    }

    private var currentHour: Int {
        calendar.component(.hour, from: Date())
    }

    private enum TimeBlock: CaseIterable {
        case wake, twoHours, fourHours, sixHours, eightHours, windDown

        var title: String {
            switch self {
            case .wake: return "Wake"
            case .twoHours: return "2 hours after waking"
            case .fourHours: return "4 hours after waking"
            case .sixHours: return "6 hours after waking"
            case .eightHours: return "8 hours before bed"
            case .windDown: return "30 to 45 minutes before bed"
            }
        }

        var subtitle: String {
            switch self {
            case .wake: return "First 15 minutes"
            case .twoHours: return "First work block"
            case .fourHours: return "Reset block"
            case .sixHours: return "Midday review"
            case .eightHours: return "Close the day"
            case .windDown: return "Wind-down"
            }
        }
    }

    private var currentTimeBlock: TimeBlock {
        switch currentHour {
        case 5...8:
            return .wake
        case 9...11:
            return .twoHours
        case 12...14:
            return .fourHours
        case 15...17:
            return .sixHours
        case 18...20:
            return .eightHours
        default:
            return .windDown
        }
    }

    private var nextTimeBlock: TimeBlock {
        switch currentTimeBlock {
        case .wake: return .twoHours
        case .twoHours: return .fourHours
        case .fourHours: return .sixHours
        case .sixHours: return .eightHours
        case .eightHours: return .windDown
        case .windDown: return .wake
        }
    }

    private var todayPriority: String {
        switch weekPhase {
        case .earlyWeek:
            return "Start the day with the morning block and set your pace."
        case .midweek:
            return "Protect the routine and do not let the day fragment the plan."
        case .lateWeek:
            return "Close gaps, finish one block, and prepare the week review."
        case .weekend:
            return "Keep one anchor block alive so the routine does not collapse."
        }
    }

    private var currentBlock: (title: String, subtitle: String, steps: [String], symbol: String) {
        switch currentTimeBlock {
        case .wake:
            return hourlyScaffold[0]
        case .twoHours:
            return hourlyScaffold[1]
        case .fourHours:
            return hourlyScaffold[2]
        case .sixHours:
            return hourlyScaffold[3]
        case .eightHours:
            return hourlyScaffold[4]
        case .windDown:
            return hourlyScaffold[5]
        }
    }

    private var nextBlock: (title: String, subtitle: String, steps: [String], symbol: String) {
        switch nextTimeBlock {
        case .wake:
            return hourlyScaffold[0]
        case .twoHours:
            return hourlyScaffold[1]
        case .fourHours:
            return hourlyScaffold[2]
        case .sixHours:
            return hourlyScaffold[3]
        case .eightHours:
            return hourlyScaffold[4]
        case .windDown:
            return hourlyScaffold[5]
        }
    }

    private let hourlyScaffold: [(title: String, subtitle: String, steps: [String], symbol: String)] = [
        (
            title: "Wake",
            subtitle: "First 15 minutes",
            steps: [
                "Body check: notice what your body is doing right now",
                "Drink water and get light exposure",
                "10 to 20 minutes of mindfulness or meditation",
                "Choose one focus word: calm, steady, clear, patient, or firm"
            ],
            symbol: "sunrise.fill"
        ),
        (
            title: "2 hours after waking",
            subtitle: "First work block",
            steps: [
                "Set one target for the next 2-hour block",
                "Use paced breathing for 2 to 3 minutes if stress is building",
                "Write the one next action after the shower or first break"
            ],
            symbol: "clock.fill"
        ),
        (
            title: "4 hours after waking",
            subtitle: "Reset block",
            steps: [
                "Use STOP if you are activated",
                "STOP = Stop, Take a step back, Observe, Proceed mindfully",
                "Choose one self-soothing action",
                "Eat, drink water, stretch, or step outside for 2 to 5 minutes"
            ],
            symbol: "arrow.clockwise.circle.fill"
        ),
        (
            title: "6 hours after waking",
            subtitle: "Midday review",
            steps: [
                "Check the diary card or selector sheet",
                "Notice one hard moment and one skill used",
                "If needed, do a brief chain analysis now instead of later"
            ],
            symbol: "list.bullet.rectangle.portrait"
        ),
        (
            title: "8 hours before bed",
            subtitle: "Close the day",
            steps: [
                "Finish the last meaningful task",
                "Set tomorrow’s one-skill focus",
                "Do 5 to 10 minutes of mindfulness, meditation, or slow breathing"
            ],
            symbol: "moon.stars.fill"
        ),
        (
            title: "30 to 45 minutes before bed",
            subtitle: "Wind-down",
            steps: [
                "Target 8 hours of sleep",
                "Lower stimulation and stop problem-solving",
                "Fill out the diary card",
                "Use the selector sheet only if you cannot name what you feel",
                "Night is complete when the diary card is done and lights-out begins"
            ],
            symbol: "bed.double.fill"
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                header
                howToUseCard
                currentBlockCard
                nextBlockCard
                hourlyScaffoldSection
                chainActionCard
            }
            .padding()
        }
        .background(DBTTheme.surface)
        .sheet(isPresented: $showChainReview) {
            ChainReviewView(isPresented: $showChainReview)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily scaffolding")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(DBTTheme.muted)
            Text("Start small. Do one useful block. Record what happened.")
                .font(.title2.bold())
                .foregroundStyle(DBTTheme.text)
            Text("First move: \(todayPriority)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DBTTheme.accent)
        }
    }

    private var howToUseCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("First move")
                .font(.headline)
            Text("Start with the next action. Use the hour groups as your daily scaffold.")
            Text("If you feel lost, follow the hour groups in order: wake, 2 hours, 4 hours, 6 hours, evening.")
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private var hourlyScaffoldSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(hourlyScaffold.enumerated()), id: \.offset) { _, block in
                    scaffoldCard(title: block.title, subtitle: block.subtitle, steps: block.steps, symbol: block.symbol)
                }
            }
            .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Full scaffold")
                    .font(.headline)
                    .textCase(.uppercase)
                    .foregroundStyle(DBTTheme.muted)
                Text("Open this if you want the whole day mapped out.")
                    .font(.subheadline)
                    .foregroundStyle(DBTTheme.text)
            }
        }
    }

    private var currentBlockCard: some View {
        scaffoldCard(
            title: "Now",
            subtitle: "\(currentBlock.title) - \(currentBlock.subtitle)",
            steps: currentBlock.steps,
            symbol: currentBlock.symbol
        )
    }

    private var nextBlockCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next up")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(DBTTheme.muted)
            scaffoldCard(
                title: nextBlock.title,
                subtitle: nextBlock.subtitle,
                steps: Array(nextBlock.steps.prefix(2)),
                symbol: nextBlock.symbol
            )
        }
    }

    private var chainActionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Chain analysis", systemImage: "arrow.triangle.branch")
                .font(.headline)
            Text("Use this after a hard moment. It is the deeper breakdown, not the daily check-in.")
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
            Button("Review a hard moment") {
                showChainReview = true
            }
            .buttonStyle(.borderedProminent)
            .tint(DBTTheme.accent)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func scaffoldCard(title: String, subtitle: String, steps: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DBTTheme.muted)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    Text("• \(step)")
                        .font(.subheadline)
                        .foregroundStyle(DBTTheme.text)
                }
            }
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

}

struct WorksheetsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section("Use in order") {
                    row("Daily Practice", detail: "Wake, 2-hour, 4-hour, 6-hour, evening scaffold.")
                    row("Diary Card", detail: "Brief daily check-in.")
                    row("Chain Analysis", detail: "After a hard event.")
                    row("Weekly Review", detail: "Measure and adjust.")
                    row("DEAR Planner", detail: "One clear request.")
                    row("Opposite Action", detail: "When urge and goal conflict.")
                    row("Crisis Plan", detail: "Write before you need it.")
                }

                section("Nightly endpoint") {
                    Text("Night is complete when the diary card is done and lights-out begins.")
                }

                section("Printable source") {
                    Text("Use the companion website for printable worksheets and tool guidance.")
                    Link("Open the website workbook", destination: URL(string: "https://techmore.github.io/dbt/worksheets.html")!)
                    Link("Open the tool guide on the website", destination: URL(string: "https://techmore.github.io/dbt/tool-guide.html")!)
                }
            }
            .padding()
        }
        .background(DBTTheme.surface)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(DBTTheme.muted)
            content()
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func row(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(DBTTheme.muted)
        }
    }
}

struct ResourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                section("Primary") {
                    link("Workbook", "https://techmore.github.io/dbt/worksheets.html")
                    link("Tool guide", "https://techmore.github.io/dbt/tool-guide.html")
                }
                section("Structured DBT") {
                    link("Behavioral Tech overview", "https://archive.behavioraltech.org/dialectical-behavior-therapy-dbt/")
                    link("Behavioral Tech DBT Skills", "https://behavioraltech.org/category/dbt-skills/")
                    link("DBT Self Help diary cards", "https://dbtselfhelp.com/diary-cards/")
                    link("DBT-LBC", "https://dbt-lbc.org/")
                    link("Find a DBT-trained therapist", "https://www.behavioraltech.org/find-a-therapist-app/")
                }
                section("Reinforcement") {
                    link("DBT-RU", "https://www.youtube.com/@DBTRU")
                    link("Peter Attia DBT interview", "https://www.youtube.com/watch?v=qA2sgsxImM8&t=8629s")
                    link("DBT core skills search", "https://www.youtube.com/results?search_query=DBT+skills+mindfulness+emotion+regulation+distress+tolerance+interpersonal+effectiveness")
                    link("Wise Mind and opposite action", "https://www.youtube.com/results?search_query=DBT+wise+mind+opposite+action")
                    link("TIPP skill", "https://www.youtube.com/results?search_query=DBT+TIPP+skill")
                    link("DEAR MAN", "https://www.youtube.com/results?search_query=DBT+DEAR+MAN")
                }
                section("Backup workbook") {
                    link("The Dialectical Behavior Therapy Skills Workbook PDF", "https://cursosdepsicologia.com.ar/wp-content/uploads/2021/05/THEDIA1.pdf")
                    link("DBT Skills Workbook PDF", "https://uploads-ssl.webflow.com/60e4eec45f2723b891728a20/6127c9afb9830c5891f1cfee_DBT-Skills-Workbook.pdf")
                }
            }
            .padding()
        }
        .background(DBTTheme.surface)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(DBTTheme.muted)
            content()
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func link(_ title: String, _ urlString: String) -> some View {
        Link(title, destination: URL(string: urlString)!)
    }
}

#Preview {
    ContentView()
}

private var appBackground: Color {
#if os(iOS)
    Color(.systemGroupedBackground)
#else
    Color(nsColor: .windowBackgroundColor)
#endif
}
