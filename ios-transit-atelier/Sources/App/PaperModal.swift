import SwiftUI

private struct ModalHeightKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

/// Dialogue-box modal that pops in with a two-step cartridge reveal.
struct PaperModal<Content: View>: View {
  var title = "HOW TO PLAY"
  var dismiss: (() -> Void)?
  @ViewBuilder let content: () -> Content
  @State private var revealed = false
  @State private var contentHeight: CGFloat = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.outline.opacity(0.7).ignoresSafeArea()
        Panel(fill: Ink.sky) {
          VStack(spacing: 0) {
            if let dismiss {
              HStack {
                PixelText(title, scale: 2, color: Ink.sun, shadow: Ink.outline)
                Spacer()
                Button(action: dismiss) {
                  PixelText("X", scale: 2, color: Ink.white)
                    .frame(width: 30, height: 30)
                    .background(Ink.ember)
                    .clipShape(PixelFrame(cut: 2))
                    .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Close")
              }
              .padding(.leading, 22)
              .padding(.trailing, 14)
              .padding(.top, 8)
              Rectangle().fill(Ink.white.opacity(0.35)).frame(height: 2).padding(.horizontal, 14)
            }
            ScrollView {
              content()
                .padding(22)
                .background(
                  GeometryReader { proxy in
                    Color.clear.preference(key: ModalHeightKey.self, value: proxy.size.height)
                  })
            }
            .frame(
              height: contentHeight == 0
                ? limit(geometry.size.height) : min(contentHeight, limit(geometry.size.height)))
          }
        }
        .onPreferenceChange(ModalHeightKey.self) { contentHeight = $0 }
        .frame(maxWidth: 420)
        .padding(.horizontal, 14)
        .padding(.vertical, 22)
        .scaleEffect(revealed || reduceMotion ? 1 : 0.6)
        .opacity(revealed || reduceMotion ? 1 : 0)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .onAppear { withAnimation(.linear(duration: 0.12)) { revealed = true } }
    }
    .accessibilityAddTraits(.isModal)
  }

  private func limit(_ height: CGFloat) -> CGFloat {
    max(120, height - 44 - (dismiss == nil ? 12 : 60))
  }
}
