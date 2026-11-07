import Foundation
import Testing
@testable import TM_DBT

@MainActor
struct PracticeStoreTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("TM-DBT-tests-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func entriesSurviveRelaunch() {
        let dir = tempDirectory()
        let store = PracticeStore(directory: dir)
        store.add(PracticeEntry(emotion: "Sad", notes: "first"))
        store.add(PracticeEntry(emotion: "Angry", notes: "second"))
        store.flush()

        let reopened = PracticeStore(directory: dir)
        #expect(reopened.entries.map(\.notes) == ["second", "first"])
    }

    @Test func reviewsCanBeSavedAndDeleted() {
        let dir = tempDirectory()
        let store = PracticeStore(directory: dir)
        let review = ChainReview(promptingEvent: "Missed a deadline")
        store.add(review)
        store.flush()
        #expect(PracticeStore(directory: dir).reviews.map(\.promptingEvent) == ["Missed a deadline"])

        store.delete(review)
        store.flush()
        #expect(PracticeStore(directory: dir).reviews.isEmpty)
    }

    @Test func checkpointsArePerDay() {
        let dir = tempDirectory()
        let store = PracticeStore(directory: dir)
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        store.toggle(.morning, on: today)
        store.toggle(.sleep, on: today)
        store.toggle(.sleep, on: today)
        store.flush()

        let reopened = PracticeStore(directory: dir)
        #expect(reopened.isDone(.morning, on: today))
        #expect(!reopened.isDone(.sleep, on: today))
        #expect(!reopened.isDone(.morning, on: yesterday))
        #expect(reopened.completedCount(on: today) == 1)
    }

    @Test func recentEntriesDropOldOnes() {
        let store = PracticeStore(directory: tempDirectory())
        let old = Calendar.current.date(byAdding: .day, value: -45, to: .now)!
        store.add(PracticeEntry(date: old, notes: "old"))
        store.add(PracticeEntry(notes: "new"))
        #expect(store.recentEntries().map(\.notes) == ["new"])
    }

    @Test func readsDataSavedByEarlierVersion() throws {
        // Older builds wrote extra per-entry checkpoint fields; they should be ignored, not break loading.
        let dir = tempDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let legacy = """
        [{"date":800000000,"emotion":"Stressed","eveningDone":false,"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF",
          "middayDone":false,"morningDone":true,"notes":"","response":"Used box breathing",
          "sleepDone":false,"trigger":"Not enough sleep"}]
        """
        try Data(legacy.utf8).write(to: dir.appendingPathComponent("practice_entries.json"))
        #expect(PracticeStore(directory: dir).entries.first?.emotion == "Stressed")
    }
}

struct DailyScheduleTests {
    @Test(arguments: [
        (5, "Wake"), (8, "Wake"), (9, "2 hours after waking"), (12, "4 hours after waking"),
        (15, "6 hours after waking"), (18, "Evening"), (21, "30 to 45 minutes before bed"),
        (0, "30 to 45 minutes before bed"), (4, "30 to 45 minutes before bed")
    ])
    func currentBlockFollowsTheClock(hour: Int, title: String) {
        #expect(DailySchedule.blocks[DailySchedule.currentIndex(hour: hour)].title == title)
    }

    @Test func nextBlockWrapsToMorning() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 23))!
        #expect(DailySchedule.next(at: lateNight, calendar: calendar).title == "Wake")
    }
}
