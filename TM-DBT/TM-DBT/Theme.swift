import SwiftUI

enum DBTTheme {
    static let accent = Color(red: 0.78, green: 0.83, blue: 0.58)
    static let accentSoft = Color(red: 0.87, green: 0.89, blue: 0.74)
    static let surface = Color(red: 0.11, green: 0.12, blue: 0.09)
    static let surface2 = Color(red: 0.17, green: 0.18, blue: 0.14)
    static let border = Color(red: 0.42, green: 0.45, blue: 0.33)
    static let text = Color.white
    static let muted = Color.white.opacity(0.72)
}

/// Filled accent button. Uses dark text so the label stays readable on the pale accent.
struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DBTTheme.surface)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DBTTheme.accent, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var accent: AccentButtonStyle { AccentButtonStyle() }
}

/// Rounded card used across all screens.
struct Card<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.headline)
                    .textCase(.uppercase)
                    .foregroundStyle(DBTTheme.muted)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DBTTheme.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DBTTheme.border, lineWidth: 1))
    }
}

/// Shared screen chrome: dark background, scrolling column, navigation title.
struct Screen<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(DBTTheme.surface)
            .navigationTitle(title)
        }
    }
}
