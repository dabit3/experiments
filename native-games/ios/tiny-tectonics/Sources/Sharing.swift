import LinkPresentation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SharedLandscape: Identifiable {
  let id = UUID()
  let image: UIImage
  let title: String
  let fileURL: URL

  init(image: UIImage, title: String) throws {
    self.image = image
    self.title = title
    fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Tiny Tectonics - \(title).png")
    guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
    try data.write(to: fileURL, options: .atomic)
  }
}

final class LandscapeActivityItem: NSObject, UIActivityItemSource {
  let landscape: SharedLandscape

  init(landscape: SharedLandscape) { self.landscape = landscape }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController)
    -> Any
  {
    landscape.fileURL
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    landscape.fileURL
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    UTType.png.identifier
  }

  func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController)
    -> LPLinkMetadata?
  {
    let metadata = LPLinkMetadata()
    metadata.title = "\(landscape.title) · Tiny Tectonics"
    metadata.imageProvider = NSItemProvider(object: landscape.image)
    metadata.iconProvider = NSItemProvider(object: landscape.image)
    return metadata
  }
}

struct NativeShare: UIViewControllerRepresentable {
  let landscape: SharedLandscape

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: [LandscapeActivityItem(landscape: landscape)], applicationActivities: nil)
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct LandscapeCard: View {
  let level: Landscape
  let heights: [Int]
  let moves: Int
  let stars: Int

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("TINY TECTONICS")
        Spacer()
        Text(String(format: "NO. %02d", level.id + 1))
      }
      .font(.system(size: 12, weight: .bold))
      .tracking(3)
      .foregroundStyle(Earth.muted)
      .padding(.top, 16)
      Diorama(
        level: level, heights: heights, travel: Double(heights.count - 1), running: true,
        celebration: true
      )
      .frame(height: 390)
      Text(level.name).font(.system(size: 46, design: .serif))
      Text("A landscape, beautifully balanced.")
        .font(.system(size: 17))
        .foregroundStyle(Earth.muted)
      Rectangle().fill(Earth.copper.opacity(0.3)).frame(height: 1).padding(.vertical, 15)
      HStack {
        Text("\(moves) \(moves == 1 ? "SHIFT" : "SHIFTS")")
        Spacer()
        Text("\(level.fossils.count) AMBER")
        Spacer()
        Text("\(stars) / 3 STARS")
      }
      .font(.system(size: 12, weight: .bold))
      .tracking(2)
    }
    .padding(40)
    .frame(width: 600, height: 720)
    .foregroundStyle(Earth.ink)
    .background(Earth.paper)
  }
}
