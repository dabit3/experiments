import SwiftUI

extension Color {
    /// Background. Pure white in light mode, pure black in dark mode.
    static let paper = Color("Paper")
    /// Foreground. Pure black in light mode, pure white in dark mode.
    static let ink = Color("Ink")
}

extension Font {
    static let mono = Font.system(.footnote, design: .monospaced)
    static let monoCaption = Font.system(.caption2, design: .monospaced)
}

/// Thin 1pt hairline used for all borders. No greys: opacity does the work.
struct Hairline: ViewModifier {
    var opacity: Double = 0.25
    var radius: CGFloat = 0
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.ink.opacity(opacity), lineWidth: 1)
        )
    }
}

extension View {
    func hairline(opacity: Double = 0.25, radius: CGFloat = 0) -> some View {
        modifier(Hairline(opacity: opacity, radius: radius))
    }
}

struct InkButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .monospaced).weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(filled ? Color.paper : Color.ink)
            .background(filled ? Color.ink : Color.paper)
            .hairline(opacity: filled ? 0 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
