import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var progress: Progress
  @State private var active: Puzzle?
  @State private var showTowns = false
  @State private var showSettings = false
  @State private var resume = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NightBackground()
        ScrollView(showsIndicators: false) {
          VStack(spacing: 0) {
            HStack {
              Eyebrow(text: "A little light goes a long way")
              Spacer()
              Button {
                showSettings = true
              } label: {
                Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
              }.accessibilityLabel("Settings").accessibilityIdentifier("settings")
            }.padding(.top, 8)
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 8) {
                Text("Lantern\nParade")
                  .font(
                    .system(
                      size: geometry.size.height < 750 ? 54 : 64, weight: .regular, design: .serif)
                  )
                  .tracking(-2).lineSpacing(-4).foregroundStyle(Ink.cream)
                  .accessibilityAddTraits(.isHeader)
                Text("One ribbon. A thousand little lights.")
                  .font(.system(size: 13)).foregroundStyle(Ink.muted)
              }
              Spacer(minLength: 0)
              VStack(spacing: 0) {
                Rectangle().fill(Ink.gold.opacity(0.45)).frame(width: 1, height: 38)
                PaperLantern(size: 40)
              }.padding(.trailing, 8)
            }.padding(.top, 16)
            ZStack {
              FestivalVignette()
              VStack {
                Spacer()
                HStack(spacing: 8) {
                  Rectangle().fill(Ink.gold.opacity(0.3)).frame(width: 28, height: 1)
                  Eyebrow(text: "The town is waiting")
                  Rectangle().fill(Ink.gold.opacity(0.3)).frame(width: 28, height: 1)
                }.offset(y: 4)
              }
            }.frame(height: min(geometry.size.width - 40, geometry.size.height * 0.4))
              .padding(.vertical, 12)
            VStack(spacing: 12) {
              Button {
                resume = progress.saved != nil && progress.saved?.completed == false
                active =
                  resume ? Towns.puzzle(id: progress.saved?.puzzleID ?? "") : progress.nextTown
              } label: {
                HStack {
                  Text(
                    progress.saved?.completed == false ? "Continue your parade" : "Begin the parade"
                  )
                  Spacer()
                  Image(systemName: "arrow.right")
                }.padding(.horizontal, 22)
              }.buttonStyle(GoldButtonStyle()).accessibilityIdentifier("begin-parade")
              HStack(spacing: 12) {
                Button {
                  resume = false
                  active = Towns.daily()
                } label: {
                  Label("Daily light", systemImage: "moon.stars")
                }.buttonStyle(GoldButtonStyle(secondary: true)).accessibilityIdentifier(
                  "daily-challenge")
                Button {
                  showTowns = true
                } label: {
                  Label("The twelve towns", systemImage: "map")
                }.buttonStyle(GoldButtonStyle(secondary: true)).accessibilityIdentifier("towns")
              }
              HStack {
                Text("\(progress.completedCount) / 12 towns illuminated")
                Spacer()
                Image(systemName: "star.fill").foregroundStyle(Ink.gold)
                Text("\(progress.stars) / 36")
              }.font(.system(size: 11, design: .monospaced)).foregroundStyle(Ink.muted).padding(
                .top, 7)
            }.padding(.top, 12)
          }.padding(.horizontal, 24).padding(.bottom, 20)
        }.clipped()
      }
    }
    .fullScreenCover(item: $active) { puzzle in
      GameView(puzzle: puzzle, restored: resume ? progress.saved : nil)
        .environmentObject(progress)
    }
    .sheet(isPresented: $showTowns) {
      TownList { puzzle in
        showTowns = false
        resume = false
        active = puzzle
      }.environmentObject(progress)
    }
    .sheet(isPresented: $showSettings) { SettingsView().environmentObject(progress) }
  }
}

struct TownList: View {
  @EnvironmentObject private var progress: Progress
  @Environment(\.dismiss) private var dismiss
  let select: (Puzzle) -> Void
  var body: some View {
    NavigationStack {
      ZStack {
        NightBackground()
        ScrollView {
          VStack(alignment: .leading, spacing: 4) {
            Text("Twelve towns.\nOne luminous journey.")
              .font(.system(size: 32, design: .serif)).foregroundStyle(Ink.cream).padding(
                .vertical, 18)
            Text(
              "Explore in any order. Earn three stars with a clean route at or under par, without a guide."
            )
            .font(.subheadline).foregroundStyle(Ink.muted).padding(.bottom, 20)
            ForEach(Array(Towns.all.enumerated()), id: \.element.id) { index, puzzle in
              Button {
                select(puzzle)
              } label: {
                HStack(spacing: 16) {
                  Text(String(format: "%02d", index + 1))
                    .font(.system(size: 16, design: .monospaced)).foregroundStyle(Ink.gold)
                  VStack(alignment: .leading, spacing: 5) {
                    Text(puzzle.title).font(.system(size: 20, design: .serif)).foregroundStyle(
                      Ink.cream)
                    Text("\(puzzle.size) × \(puzzle.size) streets · par \(puzzle.par)")
                      .font(.caption).foregroundStyle(Ink.muted)
                  }
                  Spacer()
                  Stars(count: progress.best[puzzle.id] ?? 0).font(.system(size: 9))
                }.padding(.vertical, 16)
              }.accessibilityIdentifier("town-\(index + 1)")
              Divider().overlay(Ink.muted.opacity(0.1))
            }
          }.padding(24)
        }
      }.navigationTitle("The atlas").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Done") { dismiss() }.accessibilityIdentifier("close-towns") }
    }
  }
}

struct SettingsView: View {
  @EnvironmentObject private var progress: Progress
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ZStack {
        NightBackground()
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            PaperLantern(size: 40)
            Text("A quieter kind\nof celebration.")
              .font(.system(size: 34, design: .serif)).foregroundStyle(Ink.cream)
            Toggle("Haptic feedback", isOn: $progress.haptics).accessibilityIdentifier(
              "haptics-toggle")
            Text(
              "Lantern Parade is intentionally silent. Haptics mark each step on supported iPhones."
            )
            .font(.subheadline).foregroundStyle(Ink.muted)
            Divider()
            Text("HOW TO PARADE").font(.caption.monospaced()).tracking(2).foregroundStyle(Ink.gold)
            Text(
              "Draw along neighboring street lights, or tap them one by one. Collect 1 Amber, 2 Rose, then 3 Jade. Matching lanterns open gates. Bring every color to the square without crossing your ribbon."
            )
            .font(.subheadline).foregroundStyle(Ink.cream)
            Text(
              "Undo is free. A guide reveals a possible route; using it reduces your star rating. Daily light changes at midnight UTC. All progress stays on this iPhone."
            )
            .font(.subheadline).foregroundStyle(Ink.muted)
          }.fixedSize(horizontal: false, vertical: true).padding(28)
        }
      }.navigationTitle("Under the lanterns").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Done") { dismiss() }.accessibilityIdentifier("close-settings") }
    }.presentationDetents([.large])
  }
}
