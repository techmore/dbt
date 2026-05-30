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
    }
}

private struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeEntry.date, order: .reverse) private var entries: [PracticeEntry]

    @State private var currentEntry: PracticeEntry?
    @State private var sleepGoal = "8.5 hours"

    private let morningSteps = [
        "Body check: jaw, shoulders, breathing, hands, stomach, feet",
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
        "Fill out the selector sheet",
        "Do one diary-card entry",
        "Start wind-down 30 to 45 minutes before bed",
        "No phone scrolling during wind-down"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    sleepCard
                    routineCard(title: "Morning", subtitle: "7 to 12 minutes", steps: morningSteps, symbol: "sunrise.fill")
                    routineCard(title: "Midday", subtitle: "8 to 12 minutes", steps: middaySteps, symbol: "figure.walk")
                    routineCard(title: "Evening", subtitle: "8 to 15 minutes", steps: eveningSteps, symbol: "moon.stars.fill")
                    quickActions
                    if let entry = currentEntry ?? entries.first {
                        latestCheckIn(entry)
                    }
                }
                .padding()
            }
            .background(appBackground)
            .navigationTitle("DBT Today")
            .onAppear {
                if currentEntry == nil {
                    currentEntry = entries.first ?? PracticeEntry()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily scaffolding")
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text("Start small. Do one useful block. Record what happened.")
                .font(.title2.bold())
        }
    }

    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sleep reset", systemImage: "bed.double.fill")
                    .font(.headline)
                Spacer()
                Text(sleepGoal)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Bedtime goal: 9:30 pm. Wind-down begins around 8:45 to 9:00 pm. The goal is to lower stimulation, not to get more work done.")
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 8) {
                sleepLine("Finish the last meaningful task")
                sleepLine("Stop phone scrolling")
                sleepLine("Lower lights and room stimulation")
                sleepLine("Get into bed on time")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sleepLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
    }

    private func routineCard(title: String, subtitle: String, steps: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    Text("• \(step)")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick actions", systemImage: "bolt.fill")
                .font(.headline)
            HStack(spacing: 12) {
                Link("988", destination: URL(string: "https://988lifeline.org/")!)
                Link("DBT-RU", destination: URL(string: "https://www.youtube.com/@DBTRU")!)
                Link("Worksheets", destination: URL(string: "https://techmore.github.io/dbt/worksheets.html")!)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private var appBackground: Color {
#if os(iOS)
    Color(.systemGroupedBackground)
#else
    Color(nsColor: .windowBackgroundColor)
#endif
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
                Section("YouTube reinforcement") {
                    link("DBT-RU", "https://www.youtube.com/@DBTRU")
                    link("Peter Attia DBT interview", "https://www.youtube.com/watch?v=qA2sgsxImM8&t=8629s")
                    link("DBT core skills search", "https://www.youtube.com/results?search_query=DBT+skills+mindfulness+emotion+regulation+distress+tolerance+interpersonal+effectiveness")
                }
                Section("Structured learning") {
                    link("Behavioral Tech overview", "https://archive.behavioraltech.org/dialectical-behavior-therapy-dbt/")
                    link("DBT Skills articles", "https://behavioraltech.org/category/dbt-skills/")
                    link("DBT Self Help diary cards", "https://dbtselfhelp.com/diary-cards/")
                    link("DBT-LBC", "https://dbt-lbc.org/")
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
        .modelContainer(for: PracticeEntry.self, inMemory: true)
}
