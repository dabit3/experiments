import SwiftUI

/// Only the chats the user chose to keep. Everything else never made it here.
struct HistoryView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Group {
                if app.kept.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 28, weight: .light))
                            .opacity(0.5)
                        Text("Nothing kept.")
                            .font(.system(.body, design: .monospaced))
                        Text("Chats vanish unless you bookmark them.\nThat's the point.")
                            .font(.monoCaption)
                            .foregroundStyle(Color.ink.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("historyEmpty")
                } else {
                    List {
                        ForEach(app.kept) { c in
                            Button {
                                app.open(c)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(c.displayTitle)
                                        .font(.body)
                                        .lineLimit(2)
                                    HStack(spacing: 6) {
                                        Text(c.updatedAt, format: .relative(presentation: .named))
                                        Text("·")
                                        Text("\(c.messages.count) msgs")
                                        Text("·")
                                        Text(c.modelID)
                                    }
                                    .font(.monoCaption)
                                    .foregroundStyle(Color.ink.opacity(0.45))
                                    .lineLimit(1)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.paper)
                            .listRowSeparatorTint(Color.ink.opacity(0.2))
                            .swipeActions {
                                Button(role: .destructive) {
                                    app.deleteKept(id: c.id)
                                } label: {
                                    Label("Forget", systemImage: "trash")
                                }
                                .tint(.ink)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.paper)
            .foregroundStyle(Color.ink)
            .navigationTitle("Kept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !app.kept.isEmpty {
                        Button("Forget all") { confirmClear = true }
                            .font(.mono)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.mono.weight(.semibold))
                }
            }
            .confirmationDialog("Forget all kept chats?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Forget all", role: .destructive) { app.deleteAllKept() }
            }
        }
        .presentationBackground(Color.paper)
    }
}
