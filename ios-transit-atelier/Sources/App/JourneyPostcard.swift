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

/// Shareable result card: a navy masthead over a printed map sheet with a postage-style score stamp.
struct JourneyPostcard: View {
  let game: TransitSimulation
  let best: Int

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Eyebrow("TRANSIT ATELIER", tone: Ink.gold, size: 10)
          Spacer()
          Eyebrow("SHEET \(game.city.number)", tone: Ink.paper.opacity(0.7), size: 10)
        }
        HStack(alignment: .lastTextBaseline) {
          Text(game.city.title)
            .font(.system(size: 38, design: .serif))
            .tracking(-1)
            .foregroundStyle(Ink.paperLight)
          Spacer()
          CompassRose(color: Ink.paperLight).frame(width: 26, height: 26)
        }
        Text(game.city.subtitle)
          .font(.system(size: 14, design: .serif).italic())
          .foregroundStyle(Ink.paper.opacity(0.75))
      }
      .padding(28)
      .background(Ink.header)
      ZStack(alignment: .topTrailing) {
        MapDrawing(game: game, selected: 0)
          .frame(height: 360)
          .clipped()
        stamp.padding(14)
      }
      .background(Ink.paper)
      .overlay(PaperGrain())
      Rectangle().fill(Ink.rule).frame(height: 1)
      HStack(alignment: .firstTextBaseline, spacing: 14) {
        Text("\(game.delivered)")
          .font(.system(size: 62, weight: .regular, design: .serif))
          .tracking(-2)
        VStack(alignment: .leading, spacing: 6) {
          Eyebrow("PASSENGERS DELIVERED", size: 9)
          Text(
            "Local best \(best)  ·  \(game.stations.count) stations  ·  \(Int(game.elapsed / 60))m \(Int(game.elapsed) % 60)s"
          )
          .font(.system(size: 11, design: .monospaced))
          .foregroundStyle(Ink.muted)
        }
        Spacer()
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 20)
      .background(Ink.paperLight)
    }
    .frame(width: 440)
    .foregroundStyle(Ink.navy)
    .background(Ink.paper)
  }

  private var stamp: some View {
    VStack(spacing: 2) {
      Eyebrow(game.completed ? "CLOSING BELL" : "OVERCROWDED", tone: Ink.routes[0], size: 7)
      Text(String(format: "%d:%02d", Int(game.elapsed) / 60, Int(game.elapsed) % 60))
        .font(.system(size: 15, weight: .semibold, design: .monospaced))
      Eyebrow("JOURNEY", tone: Ink.routes[0], size: 7)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Ink.paperLight.opacity(0.92))
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Ink.routes[0], style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
    )
    .rotationEffect(.degrees(-6))
  }
}
