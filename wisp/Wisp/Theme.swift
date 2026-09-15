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

/// Monochrome switch: hollow ring when off, filled track with an inverted thumb when on.
struct InkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Button {
                withAnimation(.snappy(duration: 0.2)) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? Color.ink : Color.clear)
                        .overlay(Capsule().strokeBorder(Color.ink, lineWidth: 1.5))
                    Circle()
                        .fill(configuration.isOn ? Color.paper : Color.ink)
                        .padding(4)
                }
                .frame(width: 50, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isOn ? "On" : "Off")
        }
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
