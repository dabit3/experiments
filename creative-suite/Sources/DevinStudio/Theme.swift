import SwiftUI
import AppKit
import DevinCore

enum Theme {
    static let background = Color(hex: "111312")
    static let sidebar = Color(hex: "171918")
    static let panel = Color(hex: "1D201E")
    static let elevated = Color(hex: "272B28")
    static let line = Color.white.opacity(0.08)
    static let text = Color(hex: "EFEFE7")
    static let muted = Color(hex: "969D96")
    static let accent = Color(hex: "B5E7C9")
}

extension Color {
    init(hex: String) { self.init(nsColor: NSColor(hex: hex)) }
    var hex: String { NSColor(self).hex }
}

extension NSColor {
    convenience init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(raw, radix: 16) ?? 0
        self.init(srgbRed: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
    }
    var hex: String {
        let color = usingColorSpace(.sRGB) ?? self
        return String(format: "%02X%02X%02X", Int((color.redComponent * 255).rounded()), Int((color.greenComponent * 255).rounded()), Int((color.blueComponent * 255).rounded()))
    }
}

struct DevinMark: View {
    var size: CGFloat = 34
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29).fill(Theme.accent)
            Text("d").font(.system(size: size * 0.88, weight: .heavy, design: .rounded)).foregroundStyle(Theme.background).offset(y: -size * 0.06)
            Circle().fill(Theme.background).frame(width: size * 0.115, height: size * 0.115).offset(x: size * 0.24, y: size * 0.23)
        }.frame(width: size, height: size)
    }
}

struct ToolBadge: View {
    let tool: StudioTool
    var size: CGFloat = 44
    var body: some View {
        Text(tool.monogram).font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: tool.color))
            .frame(width: size, height: size)
            .background(Color(hex: tool.color).opacity(0.1), in: RoundedRectangle(cornerRadius: size * 0.25))
            .overlay(RoundedRectangle(cornerRadius: size * 0.25).stroke(Color(hex: tool.color).opacity(0.25), lineWidth: 1))
    }
}

struct StudioButtonStyle: ButtonStyle {
    var primary = false
    var professional = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: professional ? 11 : 12, weight: .semibold))
            .padding(.horizontal, 15).padding(.vertical, professional ? 7 : 9)
            .foregroundStyle(professional ? .white : primary ? Theme.background : Theme.text)
            .background(professional ? (primary ? Color(hex: "1473E6") : ProTheme.panel) : primary ? Theme.accent : Theme.elevated, in: RoundedRectangle(cornerRadius: professional ? 3 : 7))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct IconButton: View {
    let symbol: String
    let help: String
    var active = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 14, weight: .medium))
                .foregroundStyle(active ? Theme.accent : Theme.muted)
                .frame(width: 32, height: 32)
                .background(active ? Theme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
        }.buttonStyle(.plain).help(help).accessibilityLabel(help)
    }
}

struct PanelHeading: View {
    let title: String
    var detail: String = ""
    var body: some View {
        HStack {
            Text(title.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.4)
            Spacer()
            if !detail.isEmpty { Text(detail).font(.system(size: 10, design: .monospaced)) }
        }.foregroundStyle(Theme.muted).padding(.bottom, 6)
    }
}

struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeading(title: title)
            content
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
    }
}

struct NumberField: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = -10000...10000
    var body: some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.muted)
            TextField(label, value: $value, format: .number.precision(.fractionLength(0...2)))
                .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .onChange(of: value) { _, new in
                    if !new.isFinite { value = range.lowerBound }
                    else if !range.contains(new) { value = min(range.upperBound, max(range.lowerBound, new)) }
                }
        }.padding(9).background(Theme.background, in: RoundedRectangle(cornerRadius: 5))
    }
}

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title).font(.system(size: 11)).foregroundStyle(Theme.muted)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(0...2))).font(.system(size: 10, design: .monospaced))
            }
            Slider(value: $value, in: range).tint(Theme.accent).controlSize(.small)
        }
    }
}

struct EmptyWorkspace: View {
    let symbol: String
    let title: String
    let description: String
    let button: String
    let action: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol).font(.system(size: 48, weight: .ultraLight)).foregroundStyle(Theme.accent)
            Text(title).font(.system(size: 26, weight: .medium))
            Text(description).font(.system(size: 13)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 390)
            Button(button, action: action).buttonStyle(StudioButtonStyle(primary: true)).padding(.top, 6)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

func timecode(_ seconds: Double) -> String {
    guard seconds.isFinite else { return "00:00.00" }
    let value = max(0, seconds)
    return String(format: "%02d:%05.2f", Int(value) / 60, value.truncatingRemainder(dividingBy: 60))
}
