import PhotosUI
import SwiftUI

struct LibraryView: View {
  @EnvironmentObject private var library: LibraryStore
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var opened: Negative?
  @State private var pickerItem: PhotosPickerItem?
  @State private var showRecipes = false
  @State private var showAbout = false
  @State private var deleting: Negative?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        header
        HStack(alignment: .firstTextBaseline) {
          Text("Photographs").font(TypeStyle.heading)
          Spacer()
          Text("\(library.state.negatives.count) in your library")
            .font(TypeStyle.caption).foregroundStyle(Palette.muted)
        }
        if let first = library.state.negatives.first {
          photograph(first, featured: true)
        }
        LazyVGrid(
          columns: Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: typeSize.isAccessibilitySize ? 1 : 2),
          alignment: .leading, spacing: 24
        ) {
          ForEach(library.state.negatives.dropFirst()) { negative in
            photograph(negative, featured: false)
          }
        }
        Text("Originals and edits stay on this device.")
          .font(TypeStyle.caption).foregroundStyle(Palette.muted)
          .frame(maxWidth: .infinity).padding(.vertical, 12)
      }
      .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
    }
    .background(Palette.background)
    .foregroundStyle(Palette.silver)
    .safeAreaInset(edge: .bottom) {
      importControl.buttonStyle(PrimaryButton()).disabled(library.importing)
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
        .background(Palette.background)
    }
    .fullScreenCover(item: $opened) { negative in EditorView(negative: negative) }
    .sheet(isPresented: $showRecipes) { RecipeShelf() }
    .sheet(isPresented: $showAbout) { AboutView() }
    .onChange(of: pickerItem) { _, item in
      guard let item else { return }
      Task {
        opened = await library.importPhoto(item)
        pickerItem = nil
      }
    }
    .sheet(
      isPresented: Binding(
        get: { library.error != nil }, set: { if !$0 { library.error = nil } })
    ) {
      NoticeSheet(
        title: "Couldn’t complete that", detail: library.error ?? "", actionTitle: "Dismiss"
      ) { library.error = nil }
    }
    .sheet(item: $deleting) { negative in
      NoticeSheet(
        title: "Remove photograph?",
        detail:
          "This removes \(negative.title) and its edits from Silverroom. Your Photos library is unchanged.",
        actionTitle: "Remove photograph"
      ) { library.remove(negative) }
    }
  }

  private var importControl: some View {
    let importing = library.importing
    return PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
      HStack(spacing: 10) {
        if importing { ProgressView().tint(Palette.background) } else { Image(systemName: "plus") }
        Text(importing ? "Opening photograph…" : "Import photograph")
      }
      .frame(maxWidth: .infinity)
    }
  }

  private var header: some View {
    let layout =
      typeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
      : AnyLayout(HStackLayout(alignment: .center, spacing: 4))
    return layout {
      Text("Silverroom").font(TypeStyle.display).tracking(-1.5)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 0) {
        RoundControl(symbol: "bookmark", label: "Saved recipes") { showRecipes = true }
        RoundControl(symbol: "ellipsis", label: "About Silverroom") { showAbout = true }
      }
    }
    .padding(.bottom, 8)
  }

  private func photograph(_ negative: Negative, featured: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        opened = negative
      } label: {
        GeometryReader { geometry in
          if let image = library.thumbnails[negative.id] {
            Image(uiImage: image).resizable().scaledToFill()
              .frame(width: geometry.size.width, height: geometry.size.height)
              .clipped()
          } else {
            Palette.panel.overlay { ProgressView().tint(Palette.silver) }
          }
        }
        .aspectRatio(featured ? 0.95 : 0.8, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open \(negative.title)\(negative.isSample ? ", sample photograph" : "")")
      HStack(alignment: .top, spacing: 6) {
        VStack(alignment: .leading, spacing: 5) {
          Text(negative.title).font(featured ? TypeStyle.title : TypeStyle.heading)
            .fixedSize(horizontal: false, vertical: true)
          Text(negative.isSample ? "Sample photograph" : "Imported photograph")
            .font(TypeStyle.caption).foregroundStyle(Palette.muted)
        }
        Spacer(minLength: 0)
        if !negative.isSample {
          RoundControl(symbol: "minus.circle", label: "Remove \(negative.title)") {
            deleting = negative
          }
        }
      }
    }
    .task(id: negative.settings) { await library.refreshThumbnail(negative) }
  }
}

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: "About Silverroom") { dismiss() }
      ScrollView {
        VStack(alignment: .leading, spacing: 30) {
          Text("A private darkroom.").font(TypeStyle.title).padding(.top, 16)
          section(
            "On your device",
            "Core Image processes every adjustment locally. No accounts, uploads or subscriptions.")
          section(
            "Non-destructive editing",
            "Imported originals stay untouched. Edits are saved automatically. Undo and redo are available during each editing session."
          )
          section(
            "Sample photographs",
            "The cove and Quiet morning are original AI-generated images, included to explore the tools."
          )
          section(
            "Full-resolution export",
            "Share a high-quality sRGB JPEG to Photos, Files or another app. Crop and rotation determine the dimensions. Camera and location metadata are removed."
          )
          Text("Silverroom · Version 1.0").font(TypeStyle.caption).foregroundStyle(Palette.muted)
        }
        .padding(24)
      }
    }
    .foregroundStyle(Palette.silver).background(Palette.background)
    .presentationDragIndicator(.visible)
  }

  private func section(_ title: String, _ detail: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title).font(TypeStyle.heading)
      Text(detail).font(TypeStyle.body).foregroundStyle(Palette.muted).lineSpacing(3)
    }
  }
}
