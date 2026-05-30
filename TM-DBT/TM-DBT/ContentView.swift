import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            DiaryView()
                .tabItem { Label("Diary", systemImage: "list.clipboard") }

            WorksheetsView()
                .tabItem { Label("Worksheets", systemImage: "doc.richtext") }

            ResourcesView()
                .tabItem { Label("Resources", systemImage: "play.rectangle.stack") }

            SupportView()
                .tabItem { Label("Support", systemImage: "phone.fill") }
        }
        .tint(DBTTheme.accent)
    }
}

private enum DBTTheme {
    static let accent = Color(red: 0.36, green: 0.40, blue: 0.27)
    static let accentSoft = Color(red: 0.55, green: 0.58, blue: 0.43)
    static let surface = Color(red: 0.96, green: 0.96, blue: 0.93)
    static let surface2 = Color(red: 0.91, green: 0.92, blue: 0.86)
    static let border = Color(red: 0.68, green: 0.70, blue: 0.57)
    static let text = Color(red: 0.17, green: 0.16, blue: 0.14)
    static let muted = Color(red: 0.43, green: 0.41, blue: 0.38)
}

private struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeEntry.date, order: .reverse) private var entries: [PracticeEntry]
    @Query(sort: \ChainReview.date, order: .reverse) private var chainReviews: [ChainReview]
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

    private var todayEntry: PracticeEntry? {
        entries.first(where: { calendar.isDateInToday($0.date) })
    }

    private var currentEntry: PracticeEntry {
        todayEntry ?? entries.first ?? PracticeEntry()
    }

    private var completedBlocksToday: Int {
        [currentEntry.morningDone, currentEntry.middayDone, currentEntry.eveningDone, currentEntry.sleepDone].filter { $0 }.count
    }

    private var weekSessionCount: Int {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return entries.filter { entry in
            calendar.isDate(entry.date, equalTo: weekStart, toGranularity: .weekOfYear)
                && [entry.morningDone, entry.middayDone, entry.eveningDone, entry.sleepDone].contains(true)
        }.count
    }

    private var weekBlockCount: Int {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return entries
            .filter { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }
            .map { [$0.morningDone, $0.middayDone, $0.eveningDone, $0.sleepDone].filter { $0 }.count }
            .reduce(0, +)
    }

    private var currentStreak: Int {
        let dayEntries = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while let entry = dayEntries[cursor]?.first,
              [entry.morningDone, entry.middayDone, entry.eveningDone, entry.sleepDone].contains(true) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
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

    private var nextActionTitle: String {
        switch weekPhase {
        case .earlyWeek:
            return "Today’s next action"
        case .midweek:
            return "Today’s next action"
        case .lateWeek:
            return "Today’s next action"
        case .weekend:
            return "Today’s next action"
        }
    }

    private let morningSteps = [
        "Body check: notice what your body is doing right now",
        "Choose one focus word: calm, steady, clear, patient, or firm",
        "3 minutes of paced breathing",
        "Write the one next action after the shower"
    ]

    private let middaySteps = [
        "Use STOP if stress is building",
        "Choose one self-soothing action",
        "If needed, pause and reality-check the situation"
    ]

    private let eveningSteps = [
        "Fill out the diary card",
        "Use the selector sheet only if you cannot name what you feel",
        "Start wind-down 30 to 45 minutes before bed",
        "No phone scrolling during wind-down"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    howToUseCard
                    weekStatusCard
                    nextActionCard
                    summaryCard
                    sleepCard
                    checklistCard
                    routineCard(title: "Morning", subtitle: "7 to 12 minutes", steps: morningSteps, symbol: "sunrise.fill")
                    routineCard(title: "Midday", subtitle: "8 to 12 minutes", steps: middaySteps, symbol: "figure.walk")
                    routineCard(title: "Evening", subtitle: "8 to 15 minutes", steps: eveningSteps, symbol: "moon.stars.fill")
                    chainActionCard
                    quickActions
                    if let entry = todayEntry ?? entries.first {
                        latestCheckIn(entry)
                    }
                    if let review = chainReviews.first {
                        latestChainReview(review)
                    }
                }
                .padding()
            }
            .background(DBTTheme.surface.opacity(0.5))
            .navigationTitle("DBT Today")
            .onAppear {
                seedTodayIfNeeded()
            }
            .sheet(isPresented: $showChainReview) {
                ChainReviewView(isPresented: $showChainReview)
            }
        }
    }

    private func seedTodayIfNeeded() {
        guard todayEntry == nil else { return }
        let entry = PracticeEntry(date: Date())
        modelContext.insert(entry)
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
        }
    }

    private var howToUseCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How to use this today")
                .font(.headline)
            Text("Do the next action first, then use the other blocks only if you have time.")
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
            Text(todayPriority)
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private var nextActionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(nextActionTitle)
                .font(.headline)
            Text(todayPriority)
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
            Text(actionSuccessLine)
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                statCard("Today", value: "\(completedBlocksToday)/4")
                statCard("Week", value: "\(weekBlockCount)")
                statCard("Streak", value: "\(currentStreak)")
            }
            Text("Week days with any block: \(weekSessionCount). Good progress means repeatable practice, not perfect days.")
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
        }
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var actionSuccessLine: String {
        switch weekPhase {
        case .earlyWeek:
            return "Success looks like starting clean and doing the first useful block."
        case .midweek:
            return "Success looks like staying with the plan instead of getting pulled around."
        case .lateWeek:
            return "Success looks like closing one gap before the week ends."
        case .weekend:
            return "Success looks like keeping one anchor habit alive."
        }
    }

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

    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sleep reset", systemImage: "bed.double.fill")
                    .font(.headline)
                Spacer()
                Text("8.5 hours")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DBTTheme.muted)
            }
            Text("Bedtime goal: 9:30 pm. Wind-down begins around 8:45 to 9:00 pm. The goal is to lower stimulation, not to get more work done.")
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
            VStack(alignment: .leading, spacing: 8) {
                sleepLine("Finish the last meaningful task")
                sleepLine("Stop phone scrolling")
                sleepLine("Lower lights and room stimulation")
                sleepLine("Get into bed on time")
            }
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func sleepLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(DBTTheme.text)
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today checklist", systemImage: "checklist")
                .font(.headline)
            Toggle("Morning block done", isOn: binding(\PracticeEntry.morningDone))
            Toggle("Midday block done", isOn: binding(\PracticeEntry.middayDone))
            Toggle("Evening block done", isOn: binding(\PracticeEntry.eveningDone))
            Toggle("Sleep reset done", isOn: binding(\PracticeEntry.sleepDone))
            Text("Success looks like doing the smallest useful block on purpose, then marking it. A good week is five days with at least one completed block.")
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<PracticeEntry, Bool>) -> Binding<Bool> {
        Binding(
            get: { currentEntry[keyPath: keyPath] },
            set: { newValue in
                let entry = ensureTodayEntry()
                entry[keyPath: keyPath] = newValue
            }
        )
    }

    private func ensureTodayEntry() -> PracticeEntry {
        if let todayEntry {
            return todayEntry
        }
        let entry = PracticeEntry(date: Date())
        modelContext.insert(entry)
        return entry
    }

    private func routineCard(title: String, subtitle: String, steps: [String], symbol: String) -> some View {
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

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick actions", systemImage: "bolt.fill")
                .font(.headline)
            HStack(spacing: 12) {
                Link("988", destination: URL(string: "https://988lifeline.org/")!)
                Link("Diary card", destination: URL(string: "https://techmore.github.io/dbt/worksheets.html")!)
                Button("Review a hard moment") {
                    showChainReview = true
                }
            }
            .font(.subheadline.weight(.semibold))
            .tint(DBTTheme.accent)
            Text("Use these only when they match the moment. The app works best as a repeatable daily system, not as a place to browse.")
                .font(.footnote)
                .foregroundStyle(DBTTheme.muted)
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func latestCheckIn(_ entry: PracticeEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Latest check-in", systemImage: "square.and.pencil")
                .font(.headline)
            Text("Emotion: \(entry.emotion)")
            Text("Trigger: \(entry.trigger)")
            Text("Response: \(entry.response)")
            if !entry.notes.isEmpty {
                Text("Notes: \(entry.notes)")
            }
        }
        .font(.subheadline)
        .foregroundStyle(DBTTheme.text)
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func latestChainReview(_ review: ChainReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Latest hard moment review", systemImage: "arrow.triangle.branch")
                .font(.headline)
            Text("Prompting event: \(review.promptingEvent.isEmpty ? "Not filled in" : review.promptingEvent)")
            Text("Next time: \(review.nextTime.isEmpty ? "Not filled in" : review.nextTime)")
        }
        .font(.subheadline)
        .foregroundStyle(DBTTheme.text)
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }
}

private struct ChainReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChainReview.date, order: .reverse) private var reviews: [ChainReview]
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
            .onAppear {
                if let review = reviews.first {
                    promptingEvent = review.promptingEvent
                    vulnerabilityFactors = review.vulnerabilityFactors
                    bodyThoughtsFeelings = review.bodyThoughtsFeelings
                    behavior = review.behavior
                    consequence = review.consequence
                    nextTime = review.nextTime
                }
            }
        }
    }
}

private struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeEntry.date, order: .reverse) private var entries: [PracticeEntry]

    @State private var emotion = "Overwhelmed"
    @State private var trigger = "Too much pressure + no break"
    @State private var response = "Did nothing / froze"
    @State private var notes = ""

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

                Section("Most recent") {
                    if let entry = entries.first {
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
                    row("Daily Practice", detail: "Morning, midday, evening.")
                    row("Diary Card", detail: "Brief daily check-in.")
                    row("Chain Analysis", detail: "After a hard event.")
                    row("Weekly Review", detail: "Measure and adjust.")
                    row("DEAR Planner", detail: "One clear request.")
                    row("Opposite Action", detail: "When urge and goal conflict.")
                    row("Crisis Plan", detail: "Write before you need it.")
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
                Section("Core") {
                    link("Workbook", "https://techmore.github.io/dbt/worksheets.html")
                    link("Tool guide", "https://techmore.github.io/dbt/tool-guide.html")
                    link("Behavioral Tech overview", "https://archive.behavioraltech.org/dialectical-behavior-therapy-dbt/")
                    link("Behavioral Tech DBT Skills", "https://behavioraltech.org/category/dbt-skills/")
                }
                Section("Structured DBT") {
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

private struct SupportView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Quick support") {
                    Link("988 Lifeline", destination: URL(string: "https://988lifeline.org/")!)
                    Link("Find DBT-trained clinicians", destination: URL(string: "https://www.behavioraltech.org/find-a-therapist-app/")!)
                    Link("SASH BPD support", destination: URL(string: "https://www.sashbear.org/")!)
                }
                Section("Short rules") {
                    Text("Use the smallest tool that fits the moment.")
                    Text("Diary card is a check-in, not a rumination sink.")
                    Text("Chain analysis is for learning after a rough event.")
                }
            }
            .navigationTitle("Support")
        }
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
