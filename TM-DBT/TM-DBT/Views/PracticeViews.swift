import SwiftUI

struct DiaryView: View {
    @Environment(PracticeStore.self) private var store
    @State private var emotion = "Overwhelmed"
    @State private var trigger = "Too much pressure + no break"
    @State private var response = "Did nothing / froze"
    @State private var notes = ""
    @State private var savedConfirmation = false
    @FocusState private var notesFocused: Bool

    private static let emotions = ["Overwhelmed", "Stressed", "Panicked", "Anxious", "Sad", "Angry", "Frozen"]
    private static let triggers = [
        "Too much pressure + no break",
        "Too many things at once",
        "Two obligations collided",
        "I felt like I had to be on immediately",
        "Not enough sleep",
        "Hard to identify right now"
    ]
    private static let responses = [
        "Did nothing / froze",
        "Used box breathing",
        "Used self-talk / reality check",
        "Paused and took a break",
        "Did one calming action",
        "Used a DBT skill"
    ]

    var body: some View {
        Screen(title: "Diary") {
            Card(title: "Diary card") {
                picker("Emotion", selection: $emotion, options: Self.emotions)
                picker("Trigger", selection: $trigger, options: Self.triggers)
                picker("Response", selection: $response, options: Self.responses)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($notesFocused)
                    .padding(10)
                    .background(DBTTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
                HStack {
                    Button("Save check-in", action: save)
                        .buttonStyle(.accent)
                    if savedConfirmation {
                        Label("Saved", systemImage: "checkmark")
                            .font(.subheadline)
                            .foregroundStyle(DBTTheme.accent)
                    }
                }
            }

            let recent = store.recentEntries()
            Card(title: "Last 30 days") {
                Text("Review is optional. Use this only to spot a pattern, not to re-live the day.")
                    .font(.footnote)
                    .foregroundStyle(DBTTheme.muted)
                if recent.isEmpty {
                    Text("No check-ins yet.")
                        .foregroundStyle(DBTTheme.muted)
                } else {
                    DisclosureGroup("\(recent.count) check-in\(recent.count == 1 ? "" : "s")") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recent) { entry in
                                EntryRow(entry: entry)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }

            Card(title: "Hard moment reviews") {
                if store.reviews.isEmpty {
                    Text("None yet. Start one from Today → Chain analysis.")
                        .foregroundStyle(DBTTheme.muted)
                } else {
                    ForEach(store.reviews) { review in
                        NavigationLink {
                            ChainReviewDetail(review: review)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(review.promptingEvent)
                                    .lineLimit(2)
                                    .foregroundStyle(DBTTheme.text)
                                Text(review.date, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(DBTTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func save() {
        store.add(PracticeEntry(emotion: emotion, trigger: trigger, response: response, notes: notes))
        notes = ""
        notesFocused = false
        withAnimation { savedConfirmation = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { savedConfirmation = false }
        }
    }

    private func picker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

private struct EntryRow: View {
    let entry: PracticeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.date, format: .dateTime.weekday().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(DBTTheme.muted)
            Text("\(entry.emotion) · \(entry.trigger)")
                .font(.subheadline.weight(.semibold))
            Text(entry.response)
                .font(.subheadline)
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.subheadline)
                    .foregroundStyle(DBTTheme.muted)
            }
        }
    }
}

struct ChainReviewDetail: View {
    @Environment(PracticeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let review: ChainReview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(review.date, format: .dateTime.weekday().month().day().year().hour().minute())
                    .foregroundStyle(DBTTheme.muted)
                field("Prompting event", review.promptingEvent)
                field("Vulnerability factors", review.vulnerabilityFactors)
                field("Body / thoughts / feelings", review.bodyThoughtsFeelings)
                field("Behavior", review.behavior)
                field("Consequence", review.consequence)
                field("Next time", review.nextTime)
                Button("Delete review", role: .destructive) {
                    store.delete(review)
                    dismiss()
                }
                .padding(.top)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(DBTTheme.surface)
        .navigationTitle("Hard moment")
    }

    @ViewBuilder
    private func field(_ title: String, _ value: String) -> some View {
        if !value.isEmpty {
            Card(title: title) { Text(value) }
        }
    }
}

struct ChainReviewView: View {
    @Environment(PracticeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var promptingEvent = ""
    @State private var vulnerabilityFactors = ""
    @State private var bodyThoughtsFeelings = ""
    @State private var behavior = ""
    @State private var consequence = ""
    @State private var nextTime = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field("Prompting event", text: $promptingEvent, prompt: "What happened right before?")
                    field("Vulnerability factors", text: $vulnerabilityFactors, prompt: "Sleep, stress, conflict, food, pain, etc.")
                    field("Body / thoughts / feelings", text: $bodyThoughtsFeelings, prompt: "What did your body do? What were you thinking or feeling?")
                    field("Behavior", text: $behavior, prompt: "What did you do?")
                    field("Consequence", text: $consequence, prompt: "What happened right after or later?")
                    field("Next time", text: $nextTime, prompt: "What different step would fit next time?")
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(DBTTheme.surface)
            .navigationTitle("Hard moment review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.add(ChainReview(
                            promptingEvent: promptingEvent,
                            vulnerabilityFactors: vulnerabilityFactors,
                            bodyThoughtsFeelings: bodyThoughtsFeelings,
                            behavior: behavior,
                            consequence: consequence,
                            nextTime: nextTime
                        ))
                        dismiss()
                    }
                    .disabled(promptingEvent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        // Don't lose a half-written review to an accidental swipe; Cancel still closes it.
        .interactiveDismissDisabled(hasText)
    }

    private var hasText: Bool {
        [promptingEvent, vulnerabilityFactors, bodyThoughtsFeelings, behavior, consequence, nextTime]
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
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
