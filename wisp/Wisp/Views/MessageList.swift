import SwiftUI

struct MessageList: View {
    @Environment(AppState.self) private var app
    var chat: ChatController
    var burning: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if app.current.isEmpty {
                    EmptyState()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                } else {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        ForEach(app.current.messages) { message in
                            MessageRow(message: message, chat: chat)
                                .id(message.id)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .blur(radius: burning ? 14 : 0)
            .opacity(burning ? 0 : 1)
            .scaleEffect(burning ? 1.03 : 1)
            .onChange(of: app.current.messages.last?.content) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onChange(of: app.current.messages.count) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }
}

private struct EmptyState: View {
    @Environment(AppState.self) private var app
    var body: some View {
        VStack(spacing: 18) {
            WispMark(size: 40).opacity(0.7)
            Text(app.isKept
                 ? "This chat will be kept.\nIt's saved on this device as you go."
                 : "This chat is ephemeral.\nClose it and it's gone.")
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Color.ink.opacity(0.5))
            if !app.isKept {
                Label("Tap to keep it", systemImage: "bookmark")
                    .font(.monoCaption)
                    .foregroundStyle(Color.ink.opacity(0.35))
            }
        }
        .padding(.horizontal, 40)
    }
}

struct MessageRow: View {
    @Environment(AppState.self) private var app
    let message: ChatMessage
    var chat: ChatController
    @State private var showReasoning = false

    var body: some View {
        switch message.role {
        case .user: userRow
        case .assistant: assistantRow
        case .system: EmptyView()
        }
    }

    private var userRow: some View {
        HStack {
            Spacer(minLength: 48)
            Text(message.content)
                .font(.body)
                .foregroundStyle(Color.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .textSelection(.enabled)
                .contextMenu { copyButton(message.content) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You: \(message.content)")
    }

    private var assistantRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !message.reasoning.isEmpty && app.settings.showReasoning {
                ReasoningDisclosure(text: message.reasoning, live: message.isStreaming && message.content.isEmpty, expanded: $showReasoning)
            }

            if message.content.isEmpty && message.isStreaming && message.reasoning.isEmpty {
                Cursor()
            } else if !message.content.isEmpty {
                HStack(alignment: .bottom, spacing: 0) {
                    Text(LocalizedStringKey(message.content))
                        .font(.body)
                        .textSelection(.enabled)
                    if message.isStreaming { Cursor().padding(.leading, 2) }
                }
                .contextMenu { copyButton(message.content) }
            }

            if let error = message.error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(.mono)
                    Button("Retry") { chat.retryLast(app: app) }
                        .font(.mono.weight(.semibold))
                        .disabled(chat.isStreaming)
                }
                .padding(12)
                .hairline(opacity: 1)
            }

            if !message.isStreaming, message.error == nil {
                footer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assistantMessage")
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if let usage = message.usage {
                Text("\(usage.completionTokens) out")
                Text("·")
                Text("\(usage.promptTokens) in")
                if app.settings.showCost, let m = message.modelID.flatMap(app.model(withID:)) {
                    Text("·")
                    Text(Money.format(m.cost(for: usage)))
                }
            }
            if let id = message.modelID {
                if message.usage != nil { Text("·") }
                Text(id)
            }
        }
        .font(.monoCaption)
        .foregroundStyle(Color.ink.opacity(0.4))
        .lineLimit(1)
    }

    private func copyButton(_ text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }
}

private struct ReasoningDisclosure: View {
    let text: String
    let live: Bool
    @Binding var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.snappy) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(live ? "thinking" : "thought")
                    if live { Cursor(small: true) }
                }
                .font(.monoCaption)
                .foregroundStyle(Color.ink.opacity(0.55))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reasoningToggle")

            if expanded {
                Text(text)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.ink.opacity(0.6))
                    .textSelection(.enabled)
                    .padding(.leading, 10)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Color.ink.opacity(0.25)).frame(width: 1)
                    }
            }
        }
    }
}

/// A blinking block cursor: the only "typing indicator" a monochrome terminal needs.
struct Cursor: View {
    var small = false
    @State private var on = true
    var body: some View {
        Rectangle()
            .fill(Color.ink)
            .frame(width: small ? 5 : 8, height: small ? 9 : 16)
            .opacity(on ? 1 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { on = false }
            }
            .accessibilityHidden(true)
    }
}
