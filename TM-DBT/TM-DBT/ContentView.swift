import SwiftUI

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
                .tabItem { Label("Resources", systemImage: "rectangle.stack") }
        }
    }
}

struct TodayView: View {
    @Environment(PracticeStore.self) private var store
    @State private var showChainReview = false

    var body: some View {
        // Re-render each minute so "Now" follows the clock while the app stays open.
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            Screen(title: "Today") {
                header(now: now)
                ScheduleCard(label: "Now", block: DailySchedule.current(at: now))
                checkpointsCard(now: now)
                ScheduleCard(label: "Next up", block: DailySchedule.next(at: now))
                wholeDayCard
                hardMomentCard
            }
        }
        .sheet(isPresented: $showChainReview) {
            ChainReviewView()
        }
    }

    private func header(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start small. Do one useful block. Record what happened.")
                .font(.title3.bold())
                .foregroundStyle(DBTTheme.text)
            Text("First move: \(DailySchedule.weekPhase(at: now).priority)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DBTTheme.accent)
        }
    }

    private func checkpointsCard(now: Date) -> some View {
        Card(title: "Today's checkpoints · \(store.completedCount(on: now))/\(Checkpoint.allCases.count)") {
            ForEach(Checkpoint.allCases) { checkpoint in
                CheckpointRow(checkpoint: checkpoint, date: now)
            }
        }
    }

    private var wholeDayCard: some View {
        Card {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(DailySchedule.blocks) { block in
                        ScheduleCard(label: nil, block: block)
                    }
                }
                .padding(.top, 8)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Whole day")
                        .font(.headline)
                    Text("If you feel lost, follow the blocks in order.")
                        .font(.subheadline)
                        .foregroundStyle(DBTTheme.muted)
                }
            }
        }
    }

    private var hardMomentCard: some View {
        Card {
            Label("Chain analysis", systemImage: "arrow.triangle.branch")
                .font(.headline)
            Text("Use this after a hard moment. It is the deeper breakdown, not the daily check-in.")
                .font(.subheadline)
                .foregroundStyle(DBTTheme.text)
            Button("Review a hard moment") { showChainReview = true }
                .buttonStyle(.accent)
        }
    }
}

private struct CheckpointRow: View {
    @Environment(PracticeStore.self) private var store
    let checkpoint: Checkpoint
    let date: Date

    var body: some View {
        let done = store.isDone(checkpoint, on: date)
        Button {
            store.toggle(checkpoint, on: date)
        } label: {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? DBTTheme.accent : DBTTheme.muted)
                Text(checkpoint.title)
                    .foregroundStyle(DBTTheme.text)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("checkpoint-\(checkpoint.rawValue)")
        .accessibilityValue(done ? "Done" : "Not done")
    }
}

struct ScheduleCard: View {
    var label: String?
    var block: ScheduleBlock

    var body: some View {
        Card(title: label) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Label(block.title, systemImage: block.symbol).font(.headline)
                    Spacer()
                    Text(block.subtitle).font(.subheadline.weight(.medium)).foregroundStyle(DBTTheme.muted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Label(block.title, systemImage: block.symbol).font(.headline)
                    Text(block.subtitle).font(.subheadline.weight(.medium)).foregroundStyle(DBTTheme.muted)
                }
            }
            ForEach(block.steps, id: \.self) { step in
                Text("• \(step)")
                    .font(.subheadline)
                    .foregroundStyle(DBTTheme.text)
            }
        }
    }
}

struct WorksheetsView: View {
    var body: some View {
        Screen(title: "Worksheets") {
            Card(title: "Use in order") {
                row("Daily Practice", "Wake, 2-hour, 4-hour, 6-hour, evening scaffold.")
                row("Diary Card", "Brief daily check-in.")
                row("Chain Analysis", "After a hard event.")
                row("Weekly Review", "Measure and adjust.")
                row("DEAR Planner", "One clear request.")
                row("Opposite Action", "When urge and goal conflict.")
                row("Crisis Plan", "Write before you need it.")
            }
            Card(title: "Nightly endpoint") {
                Text("Night is complete when the diary card is done and lights-out begins.")
            }
            Card(title: "Printable source") {
                Text("Use the companion website for printable worksheets and tool guidance.")
                Link("Open the website workbook", destination: URL(string: "https://techmore.github.io/dbt/worksheets.html")!)
                Link("Open the tool guide on the website", destination: URL(string: "https://techmore.github.io/dbt/tool-guide.html")!)
            }
        }
    }

    private func row(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(DBTTheme.muted)
        }
    }
}

struct ResourcesView: View {
    var body: some View {
        Screen(title: "Resources") {
            Card(title: "In a crisis") {
                Text("This app is educational and does not replace therapy.")
                    .font(.subheadline)
                    .foregroundStyle(DBTTheme.muted)
                link("Call or text 988 (US)", "tel:988")
            }
            Card(title: "Primary") {
                link("Workbook", "https://techmore.github.io/dbt/worksheets.html")
                link("Tool guide", "https://techmore.github.io/dbt/tool-guide.html")
            }
            Card(title: "Structured DBT") {
                link("Behavioral Tech overview", "https://archive.behavioraltech.org/dialectical-behavior-therapy-dbt/")
                link("Behavioral Tech DBT Skills", "https://behavioraltech.org/category/dbt-skills/")
                link("DBT Self Help diary cards", "https://dbtselfhelp.com/diary-cards/")
                link("DBT-LBC", "https://dbt-lbc.org/")
                link("Find a DBT-trained therapist", "https://www.behavioraltech.org/find-a-therapist-app/")
            }
            Card(title: "Reinforcement") {
                link("DBT-RU", "https://www.youtube.com/@DBTRU")
                link("Peter Attia DBT interview", "https://www.youtube.com/watch?v=qA2sgsxImM8&t=8629s")
                link("DBT core skills search", "https://www.youtube.com/results?search_query=DBT+skills+mindfulness+emotion+regulation+distress+tolerance+interpersonal+effectiveness")
                link("Wise Mind and opposite action", "https://www.youtube.com/results?search_query=DBT+wise+mind+opposite+action")
                link("TIPP skill", "https://www.youtube.com/results?search_query=DBT+TIPP+skill")
                link("DEAR MAN", "https://www.youtube.com/results?search_query=DBT+DEAR+MAN")
            }
        }
    }

    private func link(_ title: String, _ urlString: String) -> some View {
        Link(title, destination: URL(string: urlString)!)
    }
}

#Preview {
    ContentView()
        .environment(PracticeStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("TM-DBT-preview")))
        .preferredColorScheme(.dark)
}
