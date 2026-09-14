import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmForget = false

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section {
                    Toggle("Keep new chats by default", isOn: $app.settings.keepChatsByDefault)
                        .accessibilityIdentifier("keepByDefaultToggle")
                } header: {
                    header("MEMORY")
                } footer: {
                    Text("Off means every new chat is ephemeral until you bookmark it. Kept chats are stored only on this device.")
                        .font(.monoCaption)
                }

                Section {
                    Picker("Default model", selection: $app.settings.defaultModelID) {
                        ForEach(app.models) { m in
                            Text(m.displayName).tag(m.id)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(app.settings.temperature.formatted(.number.precision(.fractionLength(1))))
                                .font(.mono)
                                .foregroundStyle(Color.ink.opacity(0.6))
                        }
                        Slider(value: $app.settings.temperature, in: 0...2, step: 0.1)
                            .tint(.ink)
                    }
                    Toggle("Show reasoning", isOn: $app.settings.showReasoning)
                    Toggle("Show token cost", isOn: $app.settings.showCost)
                } header: {
                    header("MODEL")
                }

                Section {
                    TextField("You are…", text: $app.settings.systemPrompt, axis: .vertical)
                        .lineLimit(3...10)
                        .font(.system(.footnote, design: .monospaced))
                        .onChange(of: app.settings.systemPrompt) { _, new in
                            if app.current.isEmpty { app.current.systemPrompt = new }
                        }
                } header: {
                    header("SYSTEM PROMPT")
                } footer: {
                    Text("Applies to new chats. Leave empty for the raw model.")
                        .font(.monoCaption)
                }

                Section {
                    Picker("Appearance", selection: $app.settings.appearance) {
                        ForEach(Appearance.allCases) { a in
                            Text(a.rawValue.capitalized).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    header("APPEARANCE")
                }

                Section {
                    LabeledContent("Endpoint") {
                        Text(AbliterationClient.baseURL.host() ?? "")
                            .font(.mono)
                    }
                    LabeledContent("Key") {
                        Text(maskedKey)
                            .font(.mono)
                    }
                    Button("Forget key", role: .destructive) { confirmForget = true }
                        .foregroundStyle(Color.ink)
                        .accessibilityIdentifier("forgetKeyButton")
                } header: {
                    header("ACCOUNT")
                } footer: {
                    Text("Wisp talks directly to api.abliteration.ai. No proxy, no analytics, nothing in between.")
                        .font(.monoCaption)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .foregroundStyle(Color.ink)
            .tint(.ink)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.mono.weight(.semibold))
                }
            }
            .confirmationDialog("Forget the API key on this device?", isPresented: $confirmForget, titleVisibility: .visible) {
                Button("Forget key", role: .destructive) {
                    dismiss()
                    app.forgetKey()
                }
            }
        }
        .presentationBackground(Color.paper)
    }

    private var maskedKey: String {
        guard let k = app.apiKey else { return "—" }
        guard k.count > 8 else { return "••••" }
        return "\(k.prefix(4))…\(k.suffix(4))"
    }

    private func header(_ s: String) -> some View {
        Text(s).font(.monoCaption).foregroundStyle(Color.ink.opacity(0.5))
    }
}
