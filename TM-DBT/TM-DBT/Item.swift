import Foundation

struct PracticeEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = .now
    var emotion: String = "Overwhelmed"
    var trigger: String = "Too much pressure + no break"
    var response: String = "Did nothing / froze"
    var notes: String = ""
    var morningDone: Bool = false
    var middayDone: Bool = false
    var eveningDone: Bool = false
    var sleepDone: Bool = false
}

struct ChainReview: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = .now
    var promptingEvent: String = ""
    var vulnerabilityFactors: String = ""
    var bodyThoughtsFeelings: String = ""
    var behavior: String = ""
    var consequence: String = ""
    var nextTime: String = ""
}

final class PracticeStore {
    static let shared = PracticeStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let directoryURL: URL
    private let entriesURL: URL
    private let reviewsURL: URL
    private let queue = DispatchQueue(label: "TM-DBT.PracticeStore", qos: .utility)

    private init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directoryURL = directory.appendingPathComponent("TM-DBT", isDirectory: true)
        entriesURL = directoryURL.appendingPathComponent("practice_entries.json")
        reviewsURL = directoryURL.appendingPathComponent("chain_reviews.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadEntries() -> [PracticeEntry] {
        read([PracticeEntry].self, from: entriesURL)
    }

    func loadEntriesAsync(completion: @escaping ([PracticeEntry]) -> Void) {
        queue.async {
            completion(self.read([PracticeEntry].self, from: self.entriesURL))
        }
    }

    func saveEntry(_ entry: PracticeEntry) {
        var entries = loadEntries()
        entries.append(entry)
        write(entries, to: entriesURL)
    }

    func latestEntry() -> PracticeEntry? {
        loadEntries().sorted { $0.date > $1.date }.first
    }

    func loadReviews() -> [ChainReview] {
        read([ChainReview].self, from: reviewsURL)
    }

    func loadReviewsAsync(completion: @escaping ([ChainReview]) -> Void) {
        queue.async {
            completion(self.read([ChainReview].self, from: self.reviewsURL))
        }
    }

    func saveReview(_ review: ChainReview) {
        var reviews = loadReviews()
        reviews.append(review)
        write(reviews, to: reviewsURL)
    }

    private func read<T: Decodable>(_ type: T.Type, from url: URL) -> T {
        queue.sync {
            do {
                let data = try Data(contentsOf: url)
                return try decoder.decode(T.self, from: data)
            } catch {
                return defaultValue(for: T.self)
            }
        }
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        queue.async {
            do {
                try FileManager.default.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
                let data = try self.encoder.encode(value)
                try data.write(to: url, options: [.atomic])
            } catch {
                print("TM-DBT store write failed: \(error)")
            }
        }
    }

    private func defaultValue<T>(for type: T.Type) -> T {
        if T.self == [PracticeEntry].self { return [] as! T }
        if T.self == [ChainReview].self { return [] as! T }
        fatalError("Unsupported store type: \(T.self)")
    }
}
