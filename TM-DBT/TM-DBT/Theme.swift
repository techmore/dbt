import SwiftUI

enum AppTab {
    case today, diary, worksheets, resources
}

enum DBTTheme {
    static let accent = Color(red: 0.78, green: 0.83, blue: 0.58)
    static let accentSoft = Color(red: 0.87, green: 0.89, blue: 0.74)
    static let surface = Color(red: 0.11, green: 0.12, blue: 0.09)
    static let surface2 = Color(red: 0.17, green: 0.18, blue: 0.14)
    static let border = Color(red: 0.42, green: 0.45, blue: 0.33)
    static let text = Color.white
    static let muted = Color.white.opacity(0.72)
}
