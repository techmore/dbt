import Foundation

struct ScheduleBlock: Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let steps: [String]
    let symbol: String
}

/// The hour-by-hour DBT scaffold and the rules for picking "now" and "next".
enum DailySchedule {
    static let blocks: [ScheduleBlock] = [
        ScheduleBlock(
            id: 0,
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
        ScheduleBlock(
            id: 1,
            title: "2 hours after waking",
            subtitle: "First work block",
            steps: [
                "Set one target for the next 2-hour block",
                "Use paced breathing for 2 to 3 minutes if stress is building",
                "Write the one next action after the shower or first break"
            ],
            symbol: "clock.fill"
        ),
        ScheduleBlock(
            id: 2,
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
        ScheduleBlock(
            id: 3,
            title: "6 hours after waking",
            subtitle: "Midday review",
            steps: [
                "Check the diary card or selector sheet",
                "Notice one hard moment and one skill used",
                "If needed, do a brief chain analysis now instead of later"
            ],
            symbol: "list.bullet.rectangle.portrait"
        ),
        ScheduleBlock(
            id: 4,
            title: "Evening",
            subtitle: "Close the day",
            steps: [
                "Finish the last meaningful task",
                "Set tomorrow’s one-skill focus",
                "Do 5 to 10 minutes of mindfulness, meditation, or slow breathing"
            ],
            symbol: "moon.stars.fill"
        ),
        ScheduleBlock(
            id: 5,
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

    static func currentIndex(hour: Int) -> Int {
        switch hour {
        case 5...8: return 0
        case 9...11: return 1
        case 12...14: return 2
        case 15...17: return 3
        case 18...20: return 4
        default: return 5
        }
    }

    static func current(at date: Date, calendar: Calendar = .current) -> ScheduleBlock {
        blocks[currentIndex(hour: calendar.component(.hour, from: date))]
    }

    static func next(at date: Date, calendar: Calendar = .current) -> ScheduleBlock {
        let index = currentIndex(hour: calendar.component(.hour, from: date))
        return blocks[(index + 1) % blocks.count]
    }

    enum WeekPhase: String {
        case earlyWeek = "Early week"
        case midweek = "Midweek"
        case lateWeek = "Late week"
        case weekend = "Weekend"

        var priority: String {
            switch self {
            case .earlyWeek: return "Start the day with the morning block and set your pace."
            case .midweek: return "Protect the routine and do not let the day fragment the plan."
            case .lateWeek: return "Close gaps, finish one block, and prepare the week review."
            case .weekend: return "Keep one anchor block alive so the routine does not collapse."
            }
        }
    }

    static func weekPhase(at date: Date, calendar: Calendar = .current) -> WeekPhase {
        switch calendar.component(.weekday, from: date) {
        case 1, 7: return .weekend
        case 2, 3: return .earlyWeek
        case 4, 5: return .midweek
        default: return .lateWeek
        }
    }
}
