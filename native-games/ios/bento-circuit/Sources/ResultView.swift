import LinkPresentation
import SwiftUI
import UIKit

struct ShareParcel: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct NativeShareSheet: UIViewControllerRepresentable {
  let parcel: ShareParcel
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let configuration = UIActivityItemsConfiguration(objects: [
      parcel.image, parcel.text as NSString,
    ])
    configuration.metadataProvider = { key in
      if key == .linkPresentationMetadata {
        let metadata = LPLinkMetadata()
        metadata.title = "Bento Circuit · Packed with care"
        metadata.imageProvider = NSItemProvider(object: parcel.image)
        metadata.iconProvider = NSItemProvider(object: parcel.image)
        return metadata
      }
      if key == .title { return "Bento Circuit postcard" }
      return nil
    }
    return UIActivityViewController(activityItemsConfiguration: configuration)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct LunchPostcard: View {
  let lunch: Lunch
  let game: PackingGame
  var width: CGFloat = 340

  var body: some View {
    VStack(spacing: 18) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 5) {
          Text("BENTO CIRCUIT").font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(2)
          Text(
            lunch.isDaily
              ? "THE DAILY PARCEL" : "A POSTCARD FROM STOP \(String(format: "%02d", lunch.number))"
          )
          .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1)
          .foregroundStyle(Palette.muted)
        }
        Spacer()
        Image(systemName: "tram.fill").font(.system(size: 22, weight: .light))
          .foregroundStyle(Palette.orange)
          .padding(9).overlay(
            Rectangle().stroke(Palette.orange, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
          )
          .rotationEffect(.degrees(7))
      }
      BoardView(
        lunch: lunch, game: game, cellSize: (width - 76) / CGFloat(lunch.width), showLetters: false
      )
      .rotationEffect(.degrees(-3))
      .padding(.vertical, 13)
      .accessibilityHidden(true)
      VStack(spacing: 8) {
        HStack(spacing: 9) {
          ForEach(0..<3) { index in
            Image(systemName: index < game.stars(lunch) ? "star.fill" : "star")
          }
        }.font(.system(size: 18)).foregroundStyle(Palette.orange)
        Text(game.stars(lunch) == 3 ? "Beautifully arranged." : "Packed with care.")
          .font(.system(size: 29, design: .serif)).tracking(-0.8)
          .minimumScaleFactor(0.7).lineLimit(1)
        Text(lunch.title.uppercased())
          .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.3)
          .foregroundStyle(Palette.muted)
      }
      Rectangle().fill(Palette.line).frame(height: 1)
      HStack {
        Text("\(game.moves) MOVES  ·  \(game.stars(lunch)) / 3 STARS")
        Spacer()
        Text(game.usedGuide ? "GUIDED LUNCH" : "MADE TO FIT")
      }
      .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(0.7)
      .foregroundStyle(Palette.muted)
    }
    .padding(24).frame(width: width)
    .background(Palette.paper)
    .foregroundStyle(Palette.ink)
    .overlay(Rectangle().stroke(Palette.line, lineWidth: 1).padding(7))
  }
}

struct CelebrationPetals: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scattered = false
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        ForEach(0..<24) { index in
          Capsule().fill(index.isMultiple(of: 2) ? Palette.orange.opacity(0.65) : Palette.sage)
            .frame(width: 3, height: CGFloat(5 + index % 5))
            .rotationEffect(.degrees(Double(index * 41) + (scattered ? 180 : 0)))
            .position(
              x: scattered
                ? CGFloat((index * 47 + 19) % 100) / 100 * proxy.size.width : proxy.size.width / 2,
              y: scattered ? CGFloat((index * 71 + 11) % 100) / 100 * proxy.size.height : 80
            )
            .opacity(scattered ? 0 : 0.9)
        }
      }
      .onAppear {
        withAnimation(.easeOut(duration: reduceMotion ? 0 : 2.4)) { scattered = true }
      }
    }
    .allowsHitTesting(false).accessibilityHidden(true)
  }
}

struct ResultView: View {
  let lunch: Lunch
  let game: PackingGame
  let best: Int
  let replay: () -> Void
  let next: () -> Void
  let home: () -> Void
  @State private var parcel: ShareParcel?
  @State private var shareError = false

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 20) {
          Text("READY FOR THE JOURNEY")
            .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
            .foregroundStyle(Palette.orange).padding(.top, 28)
          LunchPostcard(lunch: lunch, game: game, width: min(proxy.size.width - 40, 370))
            .shadow(color: Palette.ink.opacity(0.15), radius: 16, x: 0, y: 10)
          Text(
            game.stars(lunch) == 3
              ? "A perfect lunch. Every piece, one move."
              : (game.usedGuide
                ? "A guided lunch. Try without a guide for three stars."
                : "A lovely fit. Try one move per piece for three stars.")
          )
          .font(.system(size: 13, design: .serif)).italic()
          .foregroundStyle(Palette.muted).multilineTextAlignment(.center)
          HStack(spacing: 12) {
            Button {
              share()
            } label: {
              Label("Share postcard", systemImage: "square.and.arrow.up")
            }.buttonStyle(PrimaryButton(light: true)).accessibilityIdentifier("Share postcard")
          }
          Button(
            lunch.isDaily || lunch.number == 12 ? "Back to the journey" : "Next lunch  →",
            action: next
          )
          .buttonStyle(PrimaryButton()).accessibilityIdentifier("Next lunch")
          HStack {
            Button("Pack again", action: replay).accessibilityIdentifier("Replay")
            Spacer()
            Text("BEST  \(best) / 3").font(.system(size: 9, weight: .bold, design: .monospaced))
            Spacer()
            Button("Journey", action: home).accessibilityIdentifier("Journey")
          }
          .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 22).padding(.bottom, 28)
      }
      .overlay(CelebrationPetals())
    }
    .background(Palette.paper)
    .sheet(item: $parcel) { NativeShareSheet(parcel: $0) }
    .alert("The postcard couldn’t be prepared.", isPresented: $shareError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please try sharing again.")
    }
  }

  @MainActor private func share() {
    let renderer = ImageRenderer(content: LunchPostcard(lunch: lunch, game: game, width: 380))
    renderer.scale = 3
    guard let image = renderer.uiImage else {
      shareError = true
      return
    }
    parcel = ShareParcel(
      image: image,
      text:
        "Bento Circuit — \(lunch.title). \(game.stars(lunch))/3 stars in \(game.moves) moves. A little lunch, beautifully arranged."
    )
  }
}
