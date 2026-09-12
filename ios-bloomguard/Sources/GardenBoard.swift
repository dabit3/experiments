import SwiftUI

struct GardenBoard: View {
  @Bindable var store: GardenStore

  var body: some View {
    GeometryReader { geometry in
      let inset = 65.0
      let field = geometry.size.width - inset - 20
      let cell = field / 7.5
      let laneHeight = geometry.size.height / 5
      ZStack(alignment: .topLeading) {
        Canvas { context, size in
          context.fill(
            Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 15),
            with: .color(Color(red: 0.45, green: 0.57, blue: 0.34)))
          for row in 0..<5 {
            let y = Double(row) * laneHeight
            let rect = CGRect(x: inset, y: y + 1, width: field, height: laneHeight - 2)
            context.fill(
              Path(roundedRect: rect, cornerRadius: 7),
              with: .color(
                row % 2 == 0
                  ? Color(red: 0.62, green: 0.70, blue: 0.43)
                  : Color(red: 0.56, green: 0.65, blue: 0.38)))
            for column in 0..<7 {
              let x = inset + Double(column) * cell
              let plot = Path(
                roundedRect: CGRect(x: x + 3, y: y + 4, width: cell - 6, height: laneHeight - 8),
                cornerRadius: 8)
              context.fill(
                plot,
                with: .color(
                  (column + row) % 2 == 0 ? Color.cream.opacity(0.08) : Color.ink.opacity(0.03)))
              context.stroke(plot, with: .color(Color.cream.opacity(0.32)), lineWidth: 1)
              for fleck in 0..<4 {
                let point = CGPoint(
                  x: x + Double((column * 17 + fleck * 11) % 60) + 8,
                  y: y + Double((row * 13 + fleck * 9) % max(1, Int(laneHeight - 10))) + 5)
                var grass = Path()
                grass.move(to: point)
                grass.addLine(to: CGPoint(x: point.x + 2, y: point.y - 3))
                context.stroke(grass, with: .color(Color.ink.opacity(0.10)), lineWidth: 1)
              }
            }
          }
          for index in 0..<12 {
            let y = Double(index) * size.height / 12
            let rect = CGRect(x: size.width - 15, y: y + 1, width: 13, height: size.height / 12 - 3)
            context.fill(
              Path(roundedRect: rect, cornerRadius: 3),
              with: .color(Color(red: 0.72, green: 0.67, blue: 0.47)))
          }
        }
        VStack(spacing: 3) {
          Text("HOME").font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1)
          Cottage().frame(width: 45, height: 42)
          Text("KEEP IT\nGROWING").font(.system(size: 6, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
        }.foregroundStyle(Color.cream).position(x: 25, y: geometry.size.height / 2)
          .allowsHitTesting(false)
        ForEach(0..<5) { row in
          ZStack {
            Capsule().fill(Color.ink.opacity(0.10)).frame(width: 22, height: laneHeight - 7)
            VStack(spacing: 4) {
              Image(systemName: store.garden.rescuers.contains(row) ? "bird.fill" : "feather")
                .font(.system(size: 12)).foregroundStyle(
                  store.garden.rescuers.contains(row) ? Color.cream : Color.ink.opacity(0.3))
              Text("\(row + 1)").font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ink.opacity(0.5))
            }
          }.position(x: 52, y: (Double(row) + 0.5) * laneHeight)
          ForEach(0..<7) { column in
            Button {
              store.place(lane: row, column: column)
            } label: {
              Color.clear.contentShape(Rectangle())
            }
            .frame(width: cell, height: laneHeight)
            .position(x: inset + (Double(column) + 0.5) * cell, y: (Double(row) + 0.5) * laneHeight)
            .accessibilityLabel("Lane \(row + 1), plot \(column + 1)")
            .accessibilityIdentifier("plot-\(row)-\(column)")
          }
        }
        ForEach(store.garden.plants) { plant in
          VStack(spacing: 0) {
            GardenArt(seed: plant.seed).frame(width: laneHeight * 1.04, height: laneHeight * 0.92)
            if plant.health < plant.seed.health {
              Capsule().fill(Color.ink.opacity(0.3)).frame(width: 30, height: 3)
                .overlay(alignment: .leading) {
                  Capsule().fill(Color.gold).frame(
                    width: 30 * max(0, plant.health / plant.seed.health), height: 3)
                }
            }
          }.position(
            x: inset + (Double(plant.column) + 0.5) * cell,
            y: (Double(plant.lane) + 0.5) * laneHeight
          )
          .allowsHitTesting(false)
        }
        ForEach(store.garden.pests) { pest in
          VStack(spacing: 0) {
            PestArt(kind: pest.kind, slowed: pest.slow > 0).frame(
              width: laneHeight * 1.1, height: laneHeight * 0.88)
            Capsule().fill(Color.ink.opacity(0.25)).frame(width: 25, height: 2)
              .overlay(alignment: .leading) {
                Capsule().fill(
                  pest.slow > 0 ? Color.cyan : Color(red: 0.59, green: 0.24, blue: 0.19)
                )
                .frame(width: 25 * max(0, pest.health / pest.kind.health), height: 2)
              }
          }.position(x: inset + pest.x * cell, y: (Double(pest.lane) + 0.5) * laneHeight)
            .allowsHitTesting(false)
        }
        ForEach(store.garden.shots) { shot in
          Capsule().fill(
            shot.icy
              ? Color(red: 0.75, green: 0.92, blue: 1) : Color(red: 0.92, green: 0.96, blue: 0.50)
          )
          .frame(width: 11, height: 7)
          .shadow(color: (shot.icy ? Color.cyan : Color.gold).opacity(0.4), radius: 4)
          .position(x: inset + shot.x * cell, y: (Double(shot.lane) + 0.42) * laneHeight)
          .allowsHitTesting(false)
        }
        ForEach(store.garden.bursts) { burst in
          Circle().stroke(burst.fiery ? Color.orange : Color.cream, lineWidth: burst.fiery ? 8 : 2)
            .frame(width: (1 - burst.life / 0.7) * (burst.fiery ? cell * 3 : 24))
            .opacity(burst.life / 0.7)
            .position(x: inset + burst.x * cell, y: (Double(burst.lane) + 0.5) * laneHeight)
            .allowsHitTesting(false)
        }
        ForEach(store.garden.drops) { drop in
          Button {
            store.collect(drop.id)
          } label: {
            ZStack {
              Circle().fill(Color.gold.opacity(0.2)).frame(width: 42, height: 42)
              Image(systemName: "sun.max.fill").font(.system(size: 29)).foregroundStyle(Color.gold)
                .shadow(
                  color: Color(red: 0.54, green: 0.35, blue: 0.07).opacity(0.5), radius: 2, y: 2)
              Text("\(drop.amount)").font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(Color.ink)
            }.frame(width: 44, height: 44).contentShape(Circle())
          }.buttonStyle(.plain)
            .position(x: inset + drop.x * cell, y: (Double(drop.lane) + 0.3) * laneHeight)
            .accessibilityLabel("Gather \(drop.amount) sunshine")
        }
      }.clipped().clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.cream.opacity(0.25), lineWidth: 1))
    }
  }
}
