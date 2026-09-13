import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct JourneyExport: Transferable {
  let png: Data
  let filename: String

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .png) { journey in
      let directory = URL.cachesDirectory.appending(path: "JourneyPostcards")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let file = directory.appending(path: journey.filename)
      try journey.png.write(to: file, options: .atomic)
      return SentTransferredFile(file)
    }
  }
}

/// Shareable result card: an arcade "stage clear" screen with the finished overworld.
struct JourneyPostcard: View {
  let game: TransitSimulation
  let best: Int

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 10) {
          PixelText("TRANSIT ATELIER", scale: 2, color: Ink.sun, shadow: Ink.outline)
          PixelText(game.city.title, scale: 4, color: Ink.white, outline: Ink.outline)
          PixelText(
            "STAGE \(game.city.number)  ·  \(game.city.subtitle)", scale: 1.5, color: Ink.grey)
        }
        Spacer()
        Loco(color: Ink.routes[0], scale: 4)
      }
      .padding(26)
      .background(Ink.sky)
      Rectangle().fill(Ink.outline).frame(height: 4)
      MapDrawing(game: game, selected: 0)
        .frame(height: 360)
        .clipped()
      Rectangle().fill(Ink.outline).frame(height: 4)
      HStack(alignment: .center, spacing: 18) {
        VStack(alignment: .leading, spacing: 8) {
          PixelText("DELIVERED", scale: 1.5, color: Ink.grey)
          PixelText(
            String(format: "%04d", game.delivered), scale: 5, color: Ink.sun, shadow: Ink.outline)
        }
        VStack(alignment: .leading, spacing: 7) {
          PixelText("BEST  \(String(format: "%04d", best))", scale: 1.5, color: Ink.white)
          PixelText("STATIONS  \(game.stations.count)", scale: 1.5, color: Ink.white)
          PixelText(
            "TIME  \(String(format: "%d:%02d", Int(game.elapsed) / 60, Int(game.elapsed) % 60))",
            scale: 1.5, color: Ink.white)
        }
        Spacer()
        stamp
      }
      .padding(.horizontal, 26)
      .padding(.vertical, 22)
      .background(Ink.night)
    }
    .frame(width: 440)
    .background(Ink.night)
  }

  private var stamp: some View {
    PixelText(
      game.completed ? "STAGE\nCLEAR" : "GAME\nOVER", scale: 2.5, color: Ink.white,
      alignment: .center
    )
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(game.completed ? Ink.leaf : Ink.ember)
    .clipShape(PixelFrame())
    .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
    .rotationEffect(.degrees(-6))
  }
}
