import SwiftUI

@main
struct SilverroomApp: App {
  @StateObject private var library = LibraryStore()

  var body: some Scene {
    WindowGroup {
      LibraryView()
        .environmentObject(library)
        .font(TypeStyle.body)
        .fontDesign(.serif)
        .preferredColorScheme(.dark)
        .tint(Palette.silver)
    }
  }
}

enum Palette {
  static let background = Color(red: 0.067, green: 0.071, blue: 0.071)
  static let canvas = Color(red: 0.043, green: 0.047, blue: 0.047)
  static let panel = Color(red: 0.105, green: 0.11, blue: 0.11)
  static let silver = Color(red: 0.937, green: 0.933, blue: 0.914)
  static let muted = Color(red: 0.71, green: 0.714, blue: 0.69)
  static let amber = Color(red: 0.824, green: 0.69, blue: 0.486)
  static let line = Color.white.opacity(0.12)
}

enum TypeStyle {
  static let display = Font.custom("Georgia", size: 38, relativeTo: .largeTitle)
  static let title = Font.custom("Georgia", size: 28, relativeTo: .title2)
  static let heading = Font.system(.headline, design: .serif)
  static let body = Font.system(.body, design: .serif)
  static let label = Font.system(.subheadline, design: .serif)
  static let caption = Font.system(.footnote, design: .serif)
  static let value = Font.system(.title2, design: .serif).monospacedDigit()
}

struct RoundControl: View {
  let symbol: String
  let label: String
  var action: () -> Void
  @Environment(\.isEnabled) private var enabled

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 18, weight: .regular, design: .serif))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(enabled ? Palette.silver : Palette.muted.opacity(0.35))
    .accessibilityLabel(label)
  }
}

struct PrimaryButton: ButtonStyle {
  @Environment(\.isEnabled) private var enabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(TypeStyle.heading)
      .foregroundStyle(Palette.background)
      .padding(.horizontal, 22)
      .frame(minHeight: 54)
      .background(
        Palette.silver.opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.3),
        in: RoundedRectangle(cornerRadius: 14))
  }
}

struct Hairline: View {
  var body: some View { Rectangle().fill(Palette.line).frame(height: 0.5) }
}

struct SheetHeader: View {
  let title: String
  var onClose: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      Text(title).font(TypeStyle.heading)
        .frame(maxWidth: .infinity, alignment: .leading)
      RoundControl(symbol: "xmark", label: "Close \(title)", action: onClose)
    }
    .foregroundStyle(Palette.silver)
    .padding(.leading, 24).padding(.trailing, 12).padding(.top, 12)
    .padding(.bottom, 8)
    .background(Palette.background)
  }
}

struct NoticeSheet: View {
  @Environment(\.dismiss) private var dismiss
  let title: String
  let detail: String
  let actionTitle: String
  var action: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: title) { dismiss() }
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text(detail).font(TypeStyle.body).foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
          Button {
            action()
            dismiss()
          } label: {
            Text(actionTitle).frame(maxWidth: .infinity)
          }
          .buttonStyle(PrimaryButton())
        }
        .padding(24)
      }
    }
    .background(Palette.background)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

struct RecipeNameSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  @FocusState private var focused: Bool
  @State private var name: String
  @State private var confirmingDelete = false
  let title: String
  var onSave: (String) -> Void
  var onDelete: (() -> Void)?

  init(
    title: String, initialName: String, onSave: @escaping (String) -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.title = title
    _name = State(initialValue: initialName)
    self.onSave = onSave
    self.onDelete = onDelete
  }

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: confirmingDelete ? "Delete recipe?" : title) { dismiss() }
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          if confirmingDelete, let onDelete {
            Text("This removes the saved recipe. Photographs with this look keep their edits.")
              .font(TypeStyle.body).foregroundStyle(Palette.muted)
            Button {
              onDelete()
              dismiss()
            } label: {
              Text("Delete recipe").frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButton())
            Button("Keep recipe") { confirmingDelete = false }
              .font(TypeStyle.body).frame(maxWidth: .infinity, minHeight: 44)
          } else {
            VStack(alignment: .leading, spacing: 10) {
              Text("Recipe name").font(TypeStyle.label).foregroundStyle(Palette.muted)
              TextField("Name your look", text: $name)
                .font(TypeStyle.title).tint(Palette.silver)
                .padding(16).background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                .focused($focused).submitLabel(.done)
                .onSubmit { save() }
            }
            if !focused {
              Text(
                "Saves the look and adjustments. Crop and rotation stay with the photo."
              )
              .font(TypeStyle.label).foregroundStyle(Palette.muted)
            }
            if onDelete != nil && !focused {
              Button("Delete recipe") {
                focused = false
                confirmingDelete = true
              }
              .font(TypeStyle.label).foregroundStyle(Palette.muted)
              .frame(maxWidth: .infinity, minHeight: 44)
            }
          }
        }
        .padding(24)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if !confirmingDelete {
        Button {
          save()
        } label: {
          Text("Save recipe").frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButton()).disabled(trimmedName.isEmpty)
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
        .background(Palette.background)
      }
    }
    .foregroundStyle(Palette.silver)
    .background(Palette.background)
    .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

  private func save() {
    guard !trimmedName.isEmpty else { return }
    onSave(trimmedName)
    dismiss()
  }
}
