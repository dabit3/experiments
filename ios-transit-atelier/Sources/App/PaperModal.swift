import SwiftUI

private struct ModalHeightKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

struct PaperModal<Content: View>: View {
  var dismiss: (() -> Void)?
  @ViewBuilder let content: () -> Content
  @State private var contentHeight: CGFloat = 500

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.navy.opacity(0.45).ignoresSafeArea()
        VStack(spacing: 0) {
          if let dismiss {
            HStack {
              Text("FIELD GUIDE").font(.system(size: 9, weight: .semibold)).tracking(1.5)
              Spacer()
              Button("Close", action: dismiss)
                .font(.system(size: 12, weight: .semibold))
                .frame(minWidth: 44, minHeight: 44)
            }
            .foregroundStyle(Ink.muted)
            .padding(.horizontal, 26)
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
              contentHeight, max(120, geometry.size.height - 40 - (dismiss == nil ? 0 : 45))))
        }
        .frame(maxWidth: 420)
        .background(Ink.paper)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.6), lineWidth: 1))
        .padding(.horizontal, 20)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .onPreferenceChange(ModalHeightKey.self) { contentHeight = $0 }
    }
    .accessibilityAddTraits(.isModal)
  }
}
