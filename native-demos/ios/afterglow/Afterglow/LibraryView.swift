import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
  @ObservedObject var store: EditorStore
  let openPhoto: (SamplePhoto) -> Void
  @State private var favoritesOnly = false
  @State private var importSources = false
  @State private var filePicker = false
  @State private var photoPicker = false
  @State private var selectedPhotos: [PhotosPickerItem] = []

  private var visiblePhotos: [SamplePhoto] {
    store.photos.filter { !favoritesOnly || store.project.favorites.contains($0.id) }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 25) {
        header
        VStack(alignment: .leading, spacing: 8) {
          Eyebrow(text: "A personal photographic studio")
          Text("Find your\nsignature light.")
            .font(.system(size: 43, weight: .regular, design: .serif))
            .tracking(-1.7).lineSpacing(-4)
          Text("Originals preserved. Possibilities open.")
            .font(.system(size: 13)).foregroundStyle(muted).padding(.top, 2)
        }.padding(.top, 4)
        featured
        collectionHeader
        if visiblePhotos.isEmpty {
          VStack(spacing: 10) {
            Image(systemName: "star").font(.system(size: 26, weight: .ultraLight))
            Text("Keep the ones that move you.").font(.system(size: 18, design: .serif))
            Text("Star a photograph to collect it here.").font(.system(size: 12)).foregroundStyle(
              muted)
          }.frame(maxWidth: .infinity).padding(.vertical, 38)
        } else {
          LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 20
          ) {
            ForEach(visiblePhotos) { photo in photoCard(photo) }
            Button {
              importSources = true
            } label: {
              VStack(spacing: 12) {
                Image(systemName: "plus").font(.system(size: 24, weight: .ultraLight))
                Text("Your next original").font(.system(size: 12))
                Text("JPEG · PNG · HEIC").font(.system(size: 9, design: .monospaced))
                  .foregroundStyle(muted)
              }.frame(maxWidth: .infinity).frame(height: 213)
                .background(panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                  RoundedRectangle(cornerRadius: 10).stroke(
                    hairline, style: StrokeStyle(lineWidth: 1, dash: [4])))
            }.buttonStyle(.plain).accessibilityLabel("Import photograph")
          }
        }
        HStack(spacing: 7) {
          Image(systemName: "externaldrive").font(.system(size: 10))
          Text("LOCAL BY DESIGN").tracking(1.5)
          Spacer()
          Text("AFTERGLOW / STUDIO").tracking(1)
        }.font(.system(size: 8, design: .monospaced)).foregroundStyle(muted)
          .padding(.top, 12).padding(.bottom, 24)
      }.padding(.horizontal, 22)
    }
    .scrollIndicators(.hidden)
    .confirmationDialog("Add an original", isPresented: $importSources, titleVisibility: .visible) {
      Button("Choose from Photos") { photoPicker = true }
      Button("Import from Files") { filePicker = true }
    } message: {
      Text("Your photograph is copied into your private local library. The source stays untouched.")
    }
    .fileImporter(
      isPresented: $filePicker, allowedContentTypes: [.jpeg, .png, .heic],
      allowsMultipleSelection: true
    ) { result in
      switch result {
      case .success(let urls):
        Task { for url in urls { await store.importFile(url) } }
      case .failure(let error): store.error = error.localizedDescription
      }
    }
    .photosPicker(
      isPresented: $photoPicker, selection: $selectedPhotos, maxSelectionCount: 20,
      matching: .images
    )
    .onChange(of: selectedPhotos) { _, items in
      Task {
        for item in items {
          do {
            if let data = try await item.loadTransferable(type: Data.self) {
              await store.importData(data, title: "Imported photograph")
            }
          } catch { store.error = error.localizedDescription }
        }
        selectedPhotos = []
      }
    }
  }

  private var header: some View {
    HStack(spacing: 7) {
      Image(systemName: "circle.lefthalf.filled").foregroundStyle(amber).font(.system(size: 19))
      Text("afterglow").font(.system(size: 26, design: .serif)).tracking(-1)
      Spacer()
      Button {
        importSources = true
      } label: {
        if store.importing {
          ProgressView().tint(amber).frame(width: 85, height: 44)
        } else {
          Label("Import", systemImage: "plus")
            .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 14)
            .frame(height: 44).background(paper.opacity(0.07), in: Capsule())
        }
      }.buttonStyle(.plain).disabled(store.importing).accessibilityIdentifier("import-photo")
    }.frame(height: 57)
  }

  private var featured: some View {
    Button {
      openPhoto(store.photo)
    } label: {
      ZStack(alignment: .bottomLeading) {
        GeometryReader { proxy in
          if let image = store.libraryImages[store.photo.id] {
            Image(uiImage: image).resizable().scaledToFill()
              .frame(width: proxy.size.width, height: proxy.size.height).clipped()
          }
        }
        LinearGradient(
          colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
        VStack(alignment: .leading, spacing: 6) {
          Text("CONTINUE DEVELOPING").font(.system(size: 8, weight: .semibold)).tracking(1.8)
            .foregroundStyle(.white.opacity(0.75))
          HStack {
            Text(store.photo.title).font(.system(size: 23, design: .serif)).tracking(-0.5)
            Spacer()
            Image(systemName: "arrow.up.right").font(.system(size: 17, weight: .light))
              .frame(width: 38, height: 38).background(.ultraThinMaterial, in: Circle())
          }
        }.padding(20)
      }.frame(height: 205).clipShape(RoundedRectangle(cornerRadius: 12))
    }.buttonStyle(.plain).accessibilityLabel("Continue developing \(store.photo.title)")
      .accessibilityIdentifier("continue-editing")
  }

  private var collectionHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 5) {
        Eyebrow(text: "The collection")
        Text("\(store.photos.count) originals").font(.system(size: 12)).foregroundStyle(muted)
      }
      Spacer()
      HStack(spacing: 0) {
        filter("All", selected: !favoritesOnly) { favoritesOnly = false }
        filter("Starred", selected: favoritesOnly) { favoritesOnly = true }
      }.padding(3).background(panel, in: Capsule())
    }
  }

  private func filter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 13).frame(height: 38)
        .background(selected ? paper.opacity(0.1) : .clear, in: Capsule())
        .foregroundStyle(selected ? paper : muted)
    }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func photoCard(_ photo: SamplePhoto) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        openPhoto(photo)
      } label: {
        GeometryReader { proxy in
          ZStack(alignment: .bottomLeading) {
            if let image = store.libraryImages[photo.id] {
              Image(uiImage: image).resizable().scaledToFill()
                .frame(width: proxy.size.width, height: 172).clipped()
            } else {
              panel
            }
            if store.project.photos[photo.id]?.current != nil,
              store.project.photos[photo.id]?.current != Edit()
            {
              Text("EDITED").font(.system(size: 7, weight: .semibold)).tracking(1)
                .padding(6).background(.black.opacity(0.6), in: Capsule()).padding(8)
            }
          }.clipShape(RoundedRectangle(cornerRadius: 9))
        }.frame(height: 172)
      }.buttonStyle(.plain).accessibilityLabel("Open \(photo.title)")
        .accessibilityIdentifier("photo-\(photo.id)")
        .overlay(alignment: .topTrailing) {
          IconButton(
            icon: store.project.favorites.contains(photo.id) ? "star.fill" : "star",
            label: "Star \(photo.title)", active: store.project.favorites.contains(photo.id)
          ) {
            store.toggleFavorite(photo.id)
          }.background(.black.opacity(0.3), in: Circle()).padding(4)
        }
      Text(photo.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
      Text(photo.dimensions + (photo.isImported ? " · IMPORT" : " · STUDY"))
        .font(.system(size: 8, design: .monospaced)).foregroundStyle(muted)
    }
  }
}
