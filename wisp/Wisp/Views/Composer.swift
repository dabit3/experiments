import SwiftUI

struct Composer: View {
    @Binding var text: String
    var isStreaming: Bool
    var focused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onStop: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.ink.opacity(0.2))
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Say something…", text: $text, axis: .vertical)
                    .lineLimit(1...8)
                    .font(.body)
                    .focused(focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .hairline(opacity: focused.wrappedValue ? 0.9 : 0.3)
                    .accessibilityIdentifier("composerField")

                Button {
                    isStreaming ? onStop() : onSend()
                } label: {
                    Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(Color.paper)
                        .background(Color.ink)
                        .opacity(canSend || isStreaming ? 1 : 0.3)
                        .contentTransition(.symbolEffect(.replace))
                }
                .disabled(!canSend && !isStreaming)
                .accessibilityLabel(isStreaming ? "Stop" : "Send")
                .accessibilityIdentifier(isStreaming ? "stopButton" : "sendButton")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .animation(.easeOut(duration: 0.15), value: focused.wrappedValue)
        }
        .background(Color.paper)
    }
}
