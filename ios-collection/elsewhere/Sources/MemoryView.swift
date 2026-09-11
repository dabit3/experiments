import LinkPresentation
import SwiftUI
import UIKit

struct MemoryView: View {
  @EnvironmentObject private var journal: Journal
  @Environment(\.dismiss) private var dismiss
  let journeyID: UUID
  let memoryID: UUID
  @State private var editing = false
  @State private var deleting = false
  @State private var postcard = false

  var body: some View {
    Group {
      if let trip = journal.journey(journeyID),
        let memory = trip.stops.first(where: { $0.id == memoryID })
      {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 0) {
              MemoryArt(photo: memory.photo, style: trip.style).frame(height: 215)
              HStack {
                Eyebrow(
                  text: memory.photo == nil ? "An illustrated memory" : "From your camera roll",
                  color: Ink.muted)
                Spacer()
                Image(systemName: "sparkle").foregroundStyle(Ink.red)
              }
              .padding(14)
            }
            .padding(10).background(.white).rotationEffect(.degrees(-1.5))
            .shadow(color: Ink.navy.opacity(0.08), radius: 8, y: 4)
            HStack {
              Eyebrow(text: memory.date.formatted(.dateTime.day().month(.wide).year()))
              Spacer()
              Button {
                journal.toggleFavorite(memoryID, in: journeyID)
                UISelectionFeedbackGenerator().selectionChanged()
              } label: {
                Image(systemName: memory.isFavorite ? "heart.fill" : "heart")
                  .font(.title2).foregroundStyle(Ink.red).frame(width: 44, height: 44)
              }
              .accessibilityLabel(memory.isFavorite ? "Remove from saved" : "Save to favorites")
            }
            Text(memory.place).font(.system(.largeTitle, design: .serif)).foregroundStyle(Ink.navy)
            if memory.note.isEmpty {
              Button("Add the little details") { editing = true }
                .font(.system(.body, design: .serif)).foregroundStyle(Ink.blue)
                .padding(.vertical, 16)
            } else {
              Text(memory.note).font(.system(.title3, design: .serif))
                .lineSpacing(7).foregroundStyle(Ink.navy)
                .textSelection(.enabled)
            }
            HStack {
              Rectangle().fill(Ink.red).frame(width: 30, height: 1)
              Eyebrow(text: trip.title, color: Ink.muted)
            }
          }
          .padding(24)
        }
        .background(Ink.paper)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          ActionShelf {
            Button {
              postcard = true
            } label: {
              Label("Make a postcard", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
          }
        }
        .sheet(isPresented: $editing) { MemoryEditor(journeyID: journeyID, existing: memory) }
        .sheet(isPresented: $postcard) { PostcardView(journey: trip, memory: memory) }
      } else {
        EmptyJournal(
          title: "A memory moved on.", detail: "This stop has been removed from the journal.")
      }
    }
    .navigationTitle("A little memory").navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Edit memory", systemImage: "pencil") { editing = true }
          Button("Delete stop", systemImage: "trash", role: .destructive) { deleting = true }
        } label: {
          Image(systemName: "ellipsis").frame(width: 44, height: 44)
        }
        .accessibilityLabel("Memory options")
      }
    }
    .confirmationDialog("Delete this stop?", isPresented: $deleting, titleVisibility: .visible) {
      Button("Delete stop", role: .destructive) {
        if journal.deleteMemory(memoryID, in: journeyID) { dismiss() }
      }
    } message: {
      Text("This memory, note and photo will be removed.")
    }
  }
}

struct PostcardArtwork: View {
  var journey: Journey
  var memory: Memory
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Eyebrow(text: "A small piece of somewhere", color: Ink.blue)
        Spacer()
        Text("01").font(.system(size: 20, design: .monospaced)).foregroundStyle(Ink.red)
      }
      .padding(.bottom, 18)
      MemoryArt(photo: memory.photo, style: journey.style).frame(height: 400).clipped()
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Greetings from").font(.system(size: 24, design: .serif)).italic()
          Text(memory.place).font(.system(size: 52, design: .serif))
            .lineLimit(2).minimumScaleFactor(0.6)
        }
        Spacer(minLength: 10)
        Stamp(text: "SENT WITH\nLOVE").scaleEffect(1.1).padding(10)
      }
      .foregroundStyle(Ink.navy).padding(.top, 22)
      Text(memory.note.isEmpty ? "A moment worth keeping." : String(memory.note.prefix(220)))
        .font(.system(size: 22, design: .serif)).lineSpacing(6)
        .foregroundStyle(Ink.navy).lineLimit(5).padding(.top, 18)
      Spacer(minLength: 20)
      Rectangle().fill(Ink.navy.opacity(0.2)).frame(height: 1)
      HStack {
        Text(memory.date.formatted(.dateTime.day().month(.wide).year()))
        Spacer()
        Text("ELSEWHERE")
      }
      .font(.system(size: 13, weight: .medium, design: .monospaced)).tracking(2)
      .foregroundStyle(Ink.blue).padding(.top, 16)
    }
    .padding(32).frame(width: 600, height: 880).background(Ink.paper)
  }
}

@MainActor
enum PostcardExporter {
  static func render(journey: Journey, memory: Memory) -> UIImage? {
    let renderer = ImageRenderer(content: PostcardArtwork(journey: journey, memory: memory))
    renderer.scale = 2
    return renderer.uiImage
  }
}

struct PostcardView: View {
  @Environment(\.dismiss) private var dismiss
  var journey: Journey
  var memory: Memory
  @State private var image: UIImage?
  @State private var sharing = false
  @State private var exportError = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 22) {
          Eyebrow(text: "Some things are worth sending", color: Ink.blue)
          if let image {
            Image(uiImage: image).resizable().scaledToFit()
              .shadow(color: Ink.navy.opacity(0.12), radius: 12, y: 8)
              .accessibilityLabel("Generated postcard from \(memory.place)")
          } else if exportError {
            EmptyJournal(
              title: "Couldn't make your postcard.", detail: "Close this page and try again.")
          } else {
            ProgressView("Pressing your postcard…")
          }
          Button {
            sharing = true
          } label: {
            Label("Share postcard", systemImage: "square.and.arrow.up")
          }
          .buttonStyle(PaperButton()).disabled(image == nil)
          Text("A real image, made on your device.\nShare it, save it, or send a little hello.")
            .font(.caption).multilineTextAlignment(.center).foregroundStyle(Ink.muted)
        }
        .padding(24)
      }
      .background(Ink.pale).navigationTitle("Your postcard").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
      .task {
        image = PostcardExporter.render(journey: journey, memory: memory)
        exportError = image == nil
      }
      .sheet(isPresented: $sharing) {
        if let image { ShareSheet(image: image, title: "Greetings from \(memory.place)") }
      }
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let title: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let provider = NSItemProvider(object: image)
    provider.suggestedName = title
    let configuration = UIActivityItemsConfiguration(itemProviders: [provider])
    configuration.metadataProvider = { key in key == .title ? title : nil }
    configuration.previewProvider = { _, _, _ in provider }
    configuration.perItemMetadataProvider = { _, key in
      guard key == .linkPresentationMetadata else { return nil }
      let metadata = LPLinkMetadata()
      metadata.title = title
      metadata.imageProvider = provider
      return metadata
    }
    return UIActivityViewController(activityItemsConfiguration: configuration)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
