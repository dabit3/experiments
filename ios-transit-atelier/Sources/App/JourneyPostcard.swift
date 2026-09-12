import SwiftUI

struct JourneyPostcard: View {
  let game: TransitSimulation
  let best: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("TRANSIT ATELIER")
        Spacer()
        Text("CITY / \(game.city.number)")
      }
      .font(.system(size: 10, weight: .semibold))
      .tracking(2)
      .foregroundStyle(Ink.muted)
      Text(game.city.title).font(.system(size: 34, design: .serif))
      MapDrawing(game: game, selected: 0)
        .frame(height: 340)
        .clipped()
      Rectangle().fill(Ink.rule).frame(height: 1)
      HStack(alignment: .firstTextBaseline) {
        Text("\(game.delivered)").font(.system(size: 64, weight: .light, design: .rounded))
        Text("passengers delivered").font(.system(size: 13))
      }
      Text(
        "Local best \(best)  ·  \(game.stations.count) stations  ·  \(Int(game.elapsed / 60))m \(Int(game.elapsed) % 60)s"
      )
      .font(.system(size: 11, design: .monospaced))
      .foregroundStyle(Ink.muted)
      Text("A small study in connection.").font(.system(size: 16, design: .serif))
    }
    .padding(28)
    .frame(width: 420)
    .foregroundStyle(Ink.navy)
    .background(Ink.paper)
  }
}
