import PhotosUI
import SwiftUI
import UIKit

struct CollectionEditor: View {
  @EnvironmentObject private var museum: MuseumStore
  @Environment(\.dismiss) private var dismiss
  var existing: MuseumCollection?
  @State private var title = ""
  @State private var subtitle = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Collection name", text: $title).accessibilityIdentifier("collectionName")
          TextField("A short introduction", text: $subtitle, axis: .vertical).lineLimit(2...4)
        } header: {
          Text("Make room for your things")
        } footer: {
          Text("A collection can hold a theme, a passion, or simply the things you love.")
        }
      }
      .scrollContentBackground(.hidden).background(MuseumStyle.paper)
      .navigationTitle(existing == nil ? "New collection" : "Edit collection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            var collection = existing ?? MuseumCollection(title: "", subtitle: "")
            collection.title = title
            collection.subtitle = subtitle
            if museum.saveCollection(collection) { dismiss() }
          }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
      .onAppear {
        title = existing?.title ?? ""
        subtitle = existing?.subtitle ?? ""
      }
    }
  }
}

struct ObjectEditor: View {
  @EnvironmentObject private var museum: MuseumStore
  @Environment(\.dismiss) private var dismiss
  var collectionID: UUID
  var existing: MuseumObject?
  @State private var title = ""
  @State private var maker = ""
  @State private var story = ""
  @State private var acquired = Date()
  @State private var tags = ""
  @State private var artifact: Artifact = .vase
  @State private var photo: Data?
  @State private var pickedPhoto: PhotosPickerItem?
  @State private var loadingPhoto = false
  @State private var photoError: String?
  @State private var targetCollection: UUID?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          ExhibitArtwork(artifact: artifact, photo: photo)
            .frame(height: 175).frame(maxWidth: .infinity)
            .listRowBackground(MuseumStyle.stone.opacity(0.45))
          PhotosPicker(selection: $pickedPhoto, matching: .images, photoLibrary: .shared()) {
            Label(
              loadingPhoto
                ? "Preparing photo…" : photo == nil ? "Add your own photo" : "Replace photo",
              systemImage: "photo"
            )
            .frame(minHeight: 32)
          }.disabled(loadingPhoto)
          if photo != nil {
            Button("Remove photo", role: .destructive) {
              photo = nil
              pickedPhoto = nil
            }
          } else {
            Picker("Illustration", selection: $artifact) {
              ForEach(Artifact.allCases) { Text($0.title).tag($0) }
            }
          }
        } footer: {
          Text(
            photo == nil
              ? "Original Curio illustration. Add a photo to make it yours."
              : "Your photo stays offline, with this object.")
        }
        Section("The exhibit label") {
          TextField("Title (required)", text: $title).accessibilityIdentifier("objectTitle")
          TextField("Maker, material or year", text: $maker).accessibilityIdentifier("objectMaker")
          DatePicker("Acquired", selection: $acquired, in: ...Date(), displayedComponents: .date)
          if museum.collections.count > 1 {
            Picker("Collection", selection: $targetCollection) {
              ForEach(museum.collections) { Text($0.title).tag(Optional($0.id)) }
            }
          }
        }
        Section {
          TextField("Where did you find it? Why does it matter?", text: $story, axis: .vertical)
            .lineLimit(4...12).accessibilityIdentifier("objectStory")
        } header: {
          Text("Its story")
        }
        Section {
          TextField("ceramics, vintage, a good find", text: $tags)
            .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier(
              "objectTags")
        } header: {
          Text("Tags")
        } footer: {
          Text("Separate tags with commas. You can filter by them in your gallery.")
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .scrollContentBackground(.hidden).background(MuseumStyle.paper)
      .navigationTitle(existing == nil ? "New object" : "Edit object")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loadingPhoto)
            .accessibilityIdentifier("saveObject")
        }
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Done") {
            UIApplication.shared.sendAction(
              #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
          }
        }
      }
      .onAppear {
        if let existing {
          title = existing.title
          maker = existing.maker
          story = existing.story
          acquired = existing.acquired
          tags = existing.tags.joined(separator: ", ")
          artifact = existing.artifact
          photo = existing.photo
        }
        targetCollection = existing?.collectionID ?? collectionID
      }
      .task(id: pickedPhoto) {
        guard let pickedPhoto else { return }
        loadingPhoto = true
        defer { loadingPhoto = false }
        do {
          guard let data = try await pickedPhoto.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
          else { throw PhotoFailure.invalid }
          try Task.checkCancellation()
          let ratio = min(1, 1600 / max(image.size.width, image.size.height))
          let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
          let format = UIGraphicsImageRendererFormat()
          format.scale = 1
          let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
          }
          guard let compressed = resized.jpegData(compressionQuality: 0.85) else {
            throw PhotoFailure.invalid
          }
          photo = compressed
        } catch is CancellationError {
        } catch {
          photoError = "This photo couldn’t be opened. Try another image."
        }
      }
      .alert(
        "Photo unavailable",
        isPresented: Binding(get: { photoError != nil }, set: { if !$0 { photoError = nil } })
      ) {
        Button("OK") { photoError = nil }
      } message: {
        Text(photoError ?? "")
      }
    }
  }

  private func save() {
    var object =
      existing
      ?? MuseumObject(
        collectionID: collectionID, title: "", maker: "", story: "", acquired: Date(), tags: [],
        artifact: .vase, catalogNumber: 0)
    object.collectionID = targetCollection ?? collectionID
    object.title = title
    object.maker = maker
    object.story = story
    object.acquired = acquired
    object.tags = MuseumObject.tags(from: tags)
    object.artifact = artifact
    object.photo = photo
    if museum.saveObject(object) { dismiss() }
  }
}

private enum PhotoFailure: Error { case invalid }
