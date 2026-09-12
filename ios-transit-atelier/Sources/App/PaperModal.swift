import SwiftUI

private struct ModalHeightKey: PreferenceKey {
  static let defaultValue: CGFloat = 500
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Modal sheet styled as a printed card resting on the drafting desk.
struct PaperModal<Content: View>: View {
  var title = "FIELD GUIDE"
  var dismiss: (() -> Void)?
  @ViewBuilder let content: () -> Content
  @State private var contentHeight: CGFloat = 500
  @State private var revealed = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.navyDeep.opacity(0.62).ignoresSafeArea()
        Sheet(radius: 28) {
          VStack(spacing: 0) {
            LinearGradient(
              colors: [Ink.routes[0], Ink.routes[2], Ink.routes[1], Ink.routes[3]],
              startPoint: .leading, endPoint: .trailing
            ).frame(height: 4)
            if let dismiss {
              HStack {
                Eyebrow(title)
                Spacer()
                Button(action: dismiss) {
                  Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(Ink.paperDeep, in: Circle())
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Close")
              }
              .foregroundStyle(Ink.navy)
              .padding(.leading, 26)
              .padding(.trailing, 12)
              Rectangle().fill(Ink.rule).frame(height: 1)
            }
            ScrollView {
              content()
                .padding(26)
                .background(
                  GeometryReader { proxy in
                    Color.clear.preference(key: ModalHeightKey.self, value: proxy.size.height)
                  })
            }
            .frame(
              height: min(
                contentHeight,
                max(120, geometry.size.height - 44 - (dismiss == nil ? 4 : 49))))
          }
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 18)
        .scaleEffect(revealed || reduceMotion ? 1 : 0.94)
        .opacity(revealed || reduceMotion ? 1 : 0)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .onPreferenceChange(ModalHeightKey.self) { contentHeight = $0 }
      .onAppear { withAnimation(.spring(duration: 0.45, bounce: 0.2)) { revealed = true } }
    }
    .accessibilityAddTraits(.isModal)
  }
}
