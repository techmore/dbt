import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            DeferredTab(isActive: selectedTab == .today) {
                TodayView()
            }
            .tag(AppTab.today)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            DeferredTab(isActive: selectedTab == .diary) {
                DiaryView()
            }
            .tag(AppTab.diary)
                .tabItem { Label("Diary", systemImage: "list.clipboard") }

            DeferredTab(isActive: selectedTab == .worksheets) {
                WorksheetsView()
            }
            .tag(AppTab.worksheets)
                .tabItem { Label("Worksheets", systemImage: "doc.richtext") }

            DeferredTab(isActive: selectedTab == .resources) {
                ResourcesView()
            }
            .tag(AppTab.resources)
                .tabItem { Label("Resources", systemImage: "play.rectangle.stack") }
        }
        .tint(DBTTheme.accent)
    }
}

private enum AppTab {
    case today, diary, worksheets, resources
}

private struct DeferredTab<Content: View>: View {
    let isActive: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if isActive {
                content()
            } else {
                Color.clear
            }
        }
    }
}

private enum DBTTheme {
    static let accent = Color(red: 0.31, green: 0.35, blue: 0.22)
    static let accentSoft = Color(red: 0.52, green: 0.55, blue: 0.40)
    static let surface = Color(red: 0.95, green: 0.95, blue: 0.91)
    static let surface2 = Color(red: 0.88, green: 0.89, blue: 0.82)
    static let border = Color(red: 0.61, green: 0.64, blue: 0.49)
    static let text = Color(red: 0.16, green: 0.15, blue: 0.13)
    static let muted = Color(red: 0.41, green: 0.39, blue: 0.35)
}

private struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [PracticeEntry]
    @State private var showChainReview = false

    private let calendar = Calendar.current

    init() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        _entries = Query(
            filter: #Predicate<PracticeEntry> { $0.date >= cutoff },
            sort: \PracticeEntry.date,
            order: .reverse
        )
    }

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

    private var completedBlocksToday: Int {
        metrics.todayBlocks
    }

    private var weekSessionCount: Int {
        metrics.weekSessionCount
    }

    private var currentStreak: Int {
        metrics.currentStreak
    }

    private var currentEntry: PracticeEntry? {
        metrics.todayEntry
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

    private var isOnTrack: Bool {
        let todayBlocks = completedBlocksToday
        let activeDays = weekSessionCount
        switch weekPhase {
        case .earlyWeek:
            return activeDays >= 1 || todayBlocks >= 1
        case .midweek:
            return activeDays >= 3 || todayBlocks >= 2
        case .lateWeek:
            return activeDays >= 4 || currentStreak >= 2 || todayBlocks >= 2
        case .weekend:
            return todayBlocks >= 1 || currentStreak >= 3
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

    private var metrics: SummaryMetrics {
        SummaryMetrics(entries: entries, calendar: calendar)
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
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    header
                    howToUseCard
                    weekStatusCard
                    currentBlockCard
                    nextBlockCard
                    hourlyScaffoldSection
                    chainActionCard
                }
                .padding()
            }
            .background(DBTTheme.surface.opacity(0.5))
            .navigationTitle("DBT Today")
            .sheet(isPresented: $showChainReview) {
                ChainReviewView(isPresented: $showChainReview)
            }
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

    private var weekStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayLabel)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(DBTTheme.muted)
                    Text(weekPhase.title)
                        .font(.headline)
                        .foregroundStyle(DBTTheme.text)
                }
                Spacer()
                Text(isOnTrack ? "On track" : "Needs focus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOnTrack ? DBTTheme.accent : .red)
            }
            Text(weekPhase.guidance)
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
            Text("On track means you completed at least one useful block for this phase, not that the day was perfect.")
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
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

    private var dayLabel: String {
        Self.dayFormatter.string(from: Date())
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private func statCard(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(DBTTheme.muted)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(DBTTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<PracticeEntry, Bool>) -> Binding<Bool> {
        Binding(
            get: { currentEntry?[keyPath: keyPath] ?? false },
            set: { newValue in
                let entry = ensureTodayEntry()
                entry[keyPath: keyPath] = newValue
            }
        )
    }

    private func ensureTodayEntry() -> PracticeEntry {
        if let currentEntry {
            return currentEntry
        }
        let entry = PracticeEntry(date: Date())
        modelContext.insert(entry)
        return entry
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

    private struct SummaryMetrics {
        let todayEntry: PracticeEntry?
        let todayBlocks: Int
        let weekSessionCount: Int
        let currentStreak: Int

        init(entries: [PracticeEntry], calendar: Calendar) {
            let now = Date()
            let today = calendar.startOfDay(for: now)
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? .distantPast

            var foundToday: PracticeEntry?
            var weekCount = 0

            for entry in entries {
                if entry.date >= weekStart,
                   [entry.morningDone, entry.middayDone, entry.eveningDone, entry.sleepDone].contains(true) {
                    weekCount += 1
                }

                if foundToday == nil, calendar.isDateInToday(entry.date) {
                    foundToday = entry
                }
            }

            let todayBlocks = foundToday.map {
                [$0.morningDone, $0.middayDone, $0.eveningDone, $0.sleepDone].filter { $0 }.count
            } ?? 0

            var streak = 0
            var expectedDay = today
            var index = 0

            while index < entries.count {
                let entry = entries[index]
                let entryDay = calendar.startOfDay(for: entry.date)

                if entryDay > expectedDay {
                    index += 1
                    continue
                }

                if entryDay < expectedDay {
                    break
                }

                if [entry.morningDone, entry.middayDone, entry.eveningDone, entry.sleepDone].contains(true) {
                    streak += 1
                    guard let previous = calendar.date(byAdding: .day, value: -1, to: expectedDay) else { break }
                    expectedDay = previous
                } else {
                    break
                }

                while index < entries.count, calendar.isDate(entries[index].date, inSameDayAs: entryDay) {
                    index += 1
                }
            }

            self.todayEntry = foundToday
            self.todayBlocks = todayBlocks
            self.weekSessionCount = weekCount
            self.currentStreak = streak
        }
    }

}

private struct ChainReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var promptingEvent = ""
    @State private var vulnerabilityFactors = ""
    @State private var bodyThoughtsFeelings = ""
    @State private var behavior = ""
    @State private var consequence = ""
    @State private var nextTime = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Prompting event") {
                    TextField("What happened right before?", text: $promptingEvent, axis: .vertical)
                }
                Section("Vulnerability factors") {
                    TextField("Sleep, stress, conflict, food, pain, etc.", text: $vulnerabilityFactors, axis: .vertical)
                }
                Section("Body / thoughts / feelings") {
                    TextField("What did your body do? What were you thinking or feeling?", text: $bodyThoughtsFeelings, axis: .vertical)
                }
                Section("Behavior") {
                    TextField("What did you do?", text: $behavior, axis: .vertical)
                }
                Section("Consequence") {
                    TextField("What happened right after or later?", text: $consequence, axis: .vertical)
                }
                Section("Next time") {
                    TextField("What different step would fit next time?", text: $nextTime, axis: .vertical)
                }
                Section {
                    Button("Save hard moment review") {
                        let review = ChainReview(
                            promptingEvent: promptingEvent,
                            vulnerabilityFactors: vulnerabilityFactors,
                            bodyThoughtsFeelings: bodyThoughtsFeelings,
                            behavior: behavior,
                            consequence: consequence,
                            nextTime: nextTime
                        )
                        modelContext.insert(review)
                        isPresented = false
                    }
                    .disabled(promptingEvent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Hard Moment Review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

private struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [PracticeEntry]

    @State private var emotion = "Overwhelmed"
    @State private var trigger = "Too much pressure + no break"
    @State private var response = "Did nothing / froze"
    @State private var notes = ""
    @State private var showReview = false

    init() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        _entries = Query(
            filter: #Predicate<PracticeEntry> { $0.date >= cutoff },
            sort: \PracticeEntry.date,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Diary card") {
                    Picker("Emotion", selection: $emotion) {
                        ForEach(["Overwhelmed", "Stressed", "Panicked", "Anxious", "Sad", "Angry", "Frozen"], id: \.self) {
                            Text($0)
                        }
                    }
                    Picker("Trigger", selection: $trigger) {
                        ForEach([
                            "Too much pressure + no break",
                            "Too many things at once",
                            "Two obligations collided",
                            "I felt like I had to be on immediately",
                            "Not enough sleep",
                            "Hard to identify right now"
                        ], id: \.self) { Text($0) }
                    }
                    Picker("Response", selection: $response) {
                        ForEach([
                            "Did nothing / froze",
                            "Used box breathing",
                            "Used self-talk / reality check",
                            "Paused and took a break",
                            "Did one calming action",
                            "Used a DBT skill"
                        ], id: \.self) { Text($0) }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section {
                    Button("Save check-in") {
                        let entry = PracticeEntry(emotion: emotion, trigger: trigger, response: response, notes: notes)
                        modelContext.insert(entry)
                        notes = ""
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $showReview) {
                        if let entry = entries.first {
                            Text("Review is optional. Use this only to spot a pattern, not to re-live the day.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            LabeledContent("Emotion", value: entry.emotion)
                            LabeledContent("Trigger", value: entry.trigger)
                            LabeledContent("Response", value: entry.response)
                            if !entry.notes.isEmpty {
                                LabeledContent("Notes", value: entry.notes)
                            }
                        } else {
                            Text("No diary card saved yet.")
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Optional review")
                    }
                }
            }
            .navigationTitle("Diary")
        }
    }
}

private struct WorksheetsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Use in order") {
                    row("Daily Practice", detail: "Wake, 2-hour, 4-hour, 6-hour, evening scaffold.")
                    row("Diary Card", detail: "Brief daily check-in.")
                    row("Chain Analysis", detail: "After a hard event.")
                    row("Weekly Review", detail: "Measure and adjust.")
                    row("DEAR Planner", detail: "One clear request.")
                    row("Opposite Action", detail: "When urge and goal conflict.")
                    row("Crisis Plan", detail: "Write before you need it.")
                }

                Section("Nightly endpoint") {
                    Text("Night is complete when the diary card is done and lights-out begins.")
                }

                Section("Printable source") {
                    Text("Use the companion website for printable worksheets and tool guidance.")
                    Link("Open the website workbook", destination: URL(string: "https://techmore.github.io/dbt/worksheets.html")!)
                    Link("Open the tool guide on the website", destination: URL(string: "https://techmore.github.io/dbt/tool-guide.html")!)
                }
            }
            .navigationTitle("Worksheets")
        }
    }

    private func row(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct ResourcesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Primary") {
                    link("Workbook", "https://techmore.github.io/dbt/worksheets.html")
                    link("Tool guide", "https://techmore.github.io/dbt/tool-guide.html")
                }
                Section("Structured DBT") {
                    link("Behavioral Tech overview", "https://archive.behavioraltech.org/dialectical-behavior-therapy-dbt/")
                    link("Behavioral Tech DBT Skills", "https://behavioraltech.org/category/dbt-skills/")
                    link("DBT Self Help diary cards", "https://dbtselfhelp.com/diary-cards/")
                    link("DBT-LBC", "https://dbt-lbc.org/")
                    link("Find a DBT-trained therapist", "https://www.behavioraltech.org/find-a-therapist-app/")
                }
                Section("Reinforcement") {
                    link("DBT-RU", "https://www.youtube.com/@DBTRU")
                    link("Peter Attia DBT interview", "https://www.youtube.com/watch?v=qA2sgsxImM8&t=8629s")
                    link("DBT core skills search", "https://www.youtube.com/results?search_query=DBT+skills+mindfulness+emotion+regulation+distress+tolerance+interpersonal+effectiveness")
                    link("Wise Mind and opposite action", "https://www.youtube.com/results?search_query=DBT+wise+mind+opposite+action")
                    link("TIPP skill", "https://www.youtube.com/results?search_query=DBT+TIPP+skill")
                    link("DEAR MAN", "https://www.youtube.com/results?search_query=DBT+DEAR+MAN")
                }
                Section("Backup workbook") {
                    link("The Dialectical Behavior Therapy Skills Workbook PDF", "https://cursosdepsicologia.com.ar/wp-content/uploads/2021/05/THEDIA1.pdf")
                    link("DBT Skills Workbook PDF", "https://uploads-ssl.webflow.com/60e4eec45f2723b891728a20/6127c9afb9830c5891f1cfee_DBT-Skills-Workbook.pdf")
                }
            }
            .navigationTitle("Resources")
        }
    }

    private func link(_ title: String, _ urlString: String) -> some View {
        Link(title, destination: URL(string: urlString)!)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PracticeEntry.self, ChainReview.self], inMemory: true)
}

private var appBackground: Color {
#if os(iOS)
    Color(.systemGroupedBackground)
#else
    Color(nsColor: .windowBackgroundColor)
#endif
}
