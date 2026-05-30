import Foundation
import SwiftData

@Model
final class PracticeEntry {
    var date: Date
    var emotion: String
    var trigger: String
    var response: String
    var notes: String
    var morningDone: Bool
    var middayDone: Bool
    var eveningDone: Bool
    var sleepDone: Bool

    init(
        date: Date = .now,
        emotion: String = "Overwhelmed",
        trigger: String = "Too much pressure + no break",
        response: String = "Did nothing / froze",
        notes: String = "",
        morningDone: Bool = false,
        middayDone: Bool = false,
        eveningDone: Bool = false,
        sleepDone: Bool = false
    ) {
        self.date = date
        self.emotion = emotion
        self.trigger = trigger
        self.response = response
        self.notes = notes
        self.morningDone = morningDone
        self.middayDone = middayDone
        self.eveningDone = eveningDone
        self.sleepDone = sleepDone
    }
}
