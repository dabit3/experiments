import SwiftUI
import UIKit

struct SharedLandscape: Identifiable {
  let id = UUID()
  let image: UIImage
}

struct NativeShare: UIViewControllerRepresentable {
  let image: UIImage
  let caption: String

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, caption], applicationActivities: nil)
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
        Text("\(moves) SHIFTS")
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
