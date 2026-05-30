import SwiftUI

struct ChainReviewView: View {
    @Binding var isPresented: Bool
    @State private var store = PracticeStore.shared

    @State private var promptingEvent = ""
    @State private var vulnerabilityFactors = ""
    @State private var bodyThoughtsFeelings = ""
    @State private var behavior = ""
    @State private var consequence = ""
    @State private var nextTime = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                topActions

                fieldSection("Prompting event", text: $promptingEvent, prompt: "What happened right before?")
                fieldSection("Vulnerability factors", text: $vulnerabilityFactors, prompt: "Sleep, stress, conflict, food, pain, etc.")
                fieldSection("Body / thoughts / feelings", text: $bodyThoughtsFeelings, prompt: "What did your body do? What were you thinking or feeling?")
                fieldSection("Behavior", text: $behavior, prompt: "What did you do?")
                fieldSection("Consequence", text: $consequence, prompt: "What happened right after or later?")
                fieldSection("Next time", text: $nextTime, prompt: "What different step would fit next time?")
            }
            .padding()
        }
        .background(DBTTheme.surface)
        .safeAreaInset(edge: .top) {
            Text("Hard Moment Review")
                .font(.headline)
                .padding(.top, 8)
        }
    }

    private var topActions: some View {
        HStack {
            Button("Cancel") { isPresented = false }
            Spacer()
            Button("Save hard moment review") {
                let review = ChainReview(
                    promptingEvent: promptingEvent,
                    vulnerabilityFactors: vulnerabilityFactors,
                    bodyThoughtsFeelings: bodyThoughtsFeelings,
                    behavior: behavior,
                    consequence: consequence,
                    nextTime: nextTime
                )
                store.saveReview(review)
                isPresented = false
            }
            .disabled(promptingEvent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func fieldSection(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            TextEditor(text: text)
                .frame(minHeight: 84)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
            Text(prompt)
                .font(.caption)
                .foregroundStyle(DBTTheme.muted)
        }
    }
}

struct DiaryView: View {
    @State private var store = PracticeStore.shared
    @State private var entries: [PracticeEntry] = []
    @State private var emotion = "Overwhelmed"
    @State private var trigger = "Too much pressure + no break"
    @State private var response = "Did nothing / froze"
    @State private var notes = ""
    @State private var showReview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                sectionCard("Diary card") {
                    menuPicker("Emotion", selection: $emotion, options: ["Overwhelmed", "Stressed", "Panicked", "Anxious", "Sad", "Angry", "Frozen"])
                    menuPicker("Trigger", selection: $trigger, options: [
                        "Too much pressure + no break",
                        "Too many things at once",
                        "Two obligations collided",
                        "I felt like I had to be on immediately",
                        "Not enough sleep",
                        "Hard to identify right now"
                    ])
                    menuPicker("Response", selection: $response, options: [
                        "Did nothing / froze",
                        "Used box breathing",
                        "Used self-talk / reality check",
                        "Paused and took a break",
                        "Did one calming action",
                        "Used a DBT skill"
                    ])
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Save check-in") {
                    let entry = PracticeEntry(emotion: emotion, trigger: trigger, response: response, notes: notes)
                    store.saveEntry(entry)
                    loadRecentEntries()
                    notes = ""
                }

                DisclosureGroup(isExpanded: $showReview) {
                    if let entry = entries.first {
                        Text("Review is optional. Use this only to spot a pattern, not to re-live the day.")
                            .font(.footnote)
                            .foregroundStyle(DBTTheme.muted)
                        infoRow("Emotion", entry.emotion)
                        infoRow("Trigger", entry.trigger)
                        infoRow("Response", entry.response)
                        if !entry.notes.isEmpty {
                            infoRow("Notes", entry.notes)
                        }
                    } else {
                        Text("No diary card saved yet.")
                            .foregroundStyle(DBTTheme.muted)
                    }
                } label: {
                    Text("Optional review")
                }
            }
            .padding()
        }
        .background(DBTTheme.surface)
        .safeAreaInset(edge: .top) {
            Text("Diary")
                .font(.headline)
                .padding(.top, 8)
        }
        .onAppear {
            loadRecentEntries()
        }
    }

    private func sectionCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }

    private func menuPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(value).font(.body)
        }
    }

    private func loadRecentEntries() {
        store.loadEntriesAsync { loaded in
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
            let recent = loaded
                .filter { $0.date >= cutoff }
                .sorted { $0.date > $1.date }
            DispatchQueue.main.async {
                entries = recent
            }
        }
    }
}
