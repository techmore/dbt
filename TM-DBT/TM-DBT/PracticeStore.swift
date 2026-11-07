import Foundation
import Observation

struct PracticeEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = .now
    var emotion: String = "Overwhelmed"
    var trigger: String = "Too much pressure + no break"
    var response: String = "Did nothing / froze"
    var notes: String = ""
}

struct ChainReview: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = .now
    var promptingEvent: String = ""
    var vulnerabilityFactors: String = ""
    var bodyThoughtsFeelings: String = ""
    var behavior: String = ""
    var consequence: String = ""
    var nextTime: String = ""
}

/// The four daily check points that mark a day as "done".
enum Checkpoint: String, CaseIterable, Codable, Identifiable {
    case morning, midday, evening, sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning block"
        case .midday: return "Midday review"
        case .evening: return "Evening close"
        case .sleep: return "Diary card + lights out"
        }
    }
}

/// Holds diary entries, hard-moment reviews and daily checkpoints, saved as JSON in Application Support.
@Observable
final class PracticeStore {
    private(set) var entries: [PracticeEntry] = []
    private(set) var reviews: [ChainReview] = []
    /// Completed checkpoints keyed by day ("yyyy-MM-dd").
    private(set) var progress: [String: Set<Checkpoint>] = [:]

    @ObservationIgnored private let files: PracticeFiles

    init(directory: URL? = nil) {
        let base = directory ?? (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory).appendingPathComponent("TM-DBT", isDirectory: true)
        files = PracticeFiles(directory: base)

        // The files are a few KB, so reading them up front is cheap and means the diary is
        // filled in the moment it appears.
        entries = files.read([PracticeEntry].self, from: .entries).sorted { $0.date > $1.date }
        reviews = files.read([ChainReview].self, from: .reviews).sorted { $0.date > $1.date }
        progress = files.read([String: Set<Checkpoint>].self, from: .progress)
    }

    // MARK: Entries

    func add(_ entry: PracticeEntry) {
        entries.insert(entry, at: 0)
        files.write(entries, to: .entries)
    }

    func recentEntries(days: Int = 30, now: Date = .now) -> [PracticeEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? .distantPast
        return entries.filter { $0.date >= cutoff }
    }

    // MARK: Reviews

    func add(_ review: ChainReview) {
        reviews.insert(review, at: 0)
        files.write(reviews, to: .reviews)
    }

    func delete(_ review: ChainReview) {
        reviews.removeAll { $0.id == review.id }
        files.write(reviews, to: .reviews)
    }

    // MARK: Daily checkpoints

    func isDone(_ checkpoint: Checkpoint, on date: Date = .now) -> Bool {
        progress[Self.dayKey(date), default: []].contains(checkpoint)
    }

    func toggle(_ checkpoint: Checkpoint, on date: Date = .now) {
        let key = Self.dayKey(date)
        var done = progress[key, default: []]
        if done.contains(checkpoint) { done.remove(checkpoint) } else { done.insert(checkpoint) }
        progress[key] = done
        files.write(progress, to: .progress)
    }

    func completedCount(on date: Date = .now) -> Int {
        progress[Self.dayKey(date), default: []].count
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Blocks until queued writes have reached disk. Used by tests.
    func flush() { files.flush() }
}

/// File I/O kept off the main thread. Writes go through one serial queue so they land in order.
nonisolated final class PracticeFiles: @unchecked Sendable {
    enum Kind: String {
        case entries = "practice_entries.json"
        case reviews = "chain_reviews.json"
        case progress = "daily_progress.json"
    }

    private let directory: URL
    private let queue = DispatchQueue(label: "TM-DBT.PracticeFiles", qos: .utility)

    init(directory: URL) {
        self.directory = directory
    }

    func read<T: Decodable & EmptyInitializable>(_ type: T.Type, from kind: Kind) -> T {
        let url = directory.appendingPathComponent(kind.rawValue)
        guard let data = try? Data(contentsOf: url) else { return T() }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("TM-DBT could not read \(kind.rawValue): \(error)")
            return T()
        }
    }

    func write<T: Encodable>(_ value: T, to kind: Kind) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        let directory = directory
        let url = directory.appendingPathComponent(kind.rawValue)
        queue.async {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: url, options: [.atomic])
            } catch {
                print("TM-DBT could not save \(kind.rawValue): \(error)")
            }
        }
    }

    func flush() {
        queue.sync {}
    }
}

protocol EmptyInitializable { init() }
extension Array: EmptyInitializable {}
extension Dictionary: EmptyInitializable {}
