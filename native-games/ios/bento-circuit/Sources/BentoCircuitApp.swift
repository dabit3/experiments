import AudioToolbox
import SwiftUI
import UIKit

@MainActor @Observable
final class LunchStore {
  private let defaults: UserDefaults
  var best: [String: Int]
  var activeGames: [String: PackingGame]
  var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
  var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
  var learned: Bool { didSet { defaults.set(learned, forKey: "learned") } }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    best = defaults.dictionary(forKey: "best") as? [String: Int] ?? [:]
    if let data = defaults.data(forKey: "activeGames"),
      let decoded = try? JSONDecoder().decode([String: PackingGame].self, from: data)
    {
      activeGames = decoded
    } else {
      activeGames = [:]
    }
    sound = defaults.bool(forKey: "sound")
    haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    learned = defaults.bool(forKey: "learned")
  }

  var nextIndex: Int {
    LunchBook.all.firstIndex { best[$0.id] == nil } ?? 11
  }
  var stars: Int { LunchBook.all.reduce(0) { $0 + (best[$1.id] ?? 0) } }

  func game(for lunch: Lunch) -> PackingGame {
    if let game = activeGames[lunch.id], game.isValid(for: lunch), !game.isComplete(lunch) {
      return game
    }
    return PackingGame(lunch: lunch)
  }

  func save(_ game: PackingGame) {
    activeGames[game.lunchID] = game
    let dailyKey = LunchBook.daily().id
    activeGames = activeGames.filter { !$0.key.hasPrefix("daily-") || $0.key == dailyKey }
    if let data = try? JSONEncoder().encode(activeGames) {
      defaults.set(data, forKey: "activeGames")
    }
  }

  func finish(_ game: PackingGame, lunch: Lunch) {
    best[lunch.id] = max(best[lunch.id] ?? 0, game.stars(lunch))
    defaults.set(best, forKey: "best")
    save(game)
  }

  func feedback(success: Bool = true) {
    if haptics {
      if success {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      } else {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
      }
    }
    if sound { AudioServicesPlaySystemSound(success ? 1104 : 1053) }
  }
}

@main
struct BentoCircuitApp: App {
  @State private var store = LunchStore()
  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .preferredColorScheme(.light)
        .tint(Palette.orange)
    }
  }
}

struct RootView: View {
  @Bindable var store: LunchStore
  @State private var selectedLunch: Lunch?
  @State private var showSettings = false

  var body: some View {
    ZStack {
      PaperBackground()
      if let lunch = selectedLunch {
        GameView(lunch: lunch, store: store) {
          selectedLunch = nil
        } next: {
          if lunch.isDaily || lunch.number == 12 {
            selectedLunch = nil
          } else {
            selectedLunch = LunchBook.all[lunch.number]
          }
        }
        .id(lunch.id)
      } else {
        home
      }
    }
    .sheet(isPresented: $showSettings) { SettingsView(store: store) }
  }

  private var home: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
              Text("BENTO CIRCUIT").font(.system(size: 13, weight: .black, design: .monospaced))
                .tracking(2.5)
              Text("THE LUNCHBOX PUZZLE").font(
                .system(size: 9, weight: .medium, design: .monospaced)
              ).tracking(1.9)
                .foregroundStyle(Palette.muted)
            }
            Spacer()
            IconButton(symbol: "slider.horizontal.3", label: "Settings") { showSettings = true }
          }
          HStack(alignment: .top) {
            Text("Good things,\nbeautifully\narranged.")
              .font(
                .system(size: geometry.size.width < 390 ? 40 : 46, weight: .regular, design: .serif)
              )
              .tracking(-1.9).lineSpacing(-2)
            Spacer(minLength: 0)
            VStack(spacing: 5) {
              Image(systemName: "tram.fill").font(.system(size: 22))
              Text("12\nSTOPS").font(.system(size: 10, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
            }
            .foregroundStyle(Palette.orange)
            .padding(.top, 13)
          }
          ZStack {
            Ellipse().fill(Palette.sage.opacity(0.5))
              .frame(width: geometry.size.width - 48, height: 175)
              .rotationEffect(.degrees(-14)).offset(y: 28)
            LunchIllustration()
              .frame(width: min(geometry.size.width - 94, 310))
              .rotationEffect(.degrees(-7))
            Text("MADE TO FIT")
              .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
              .foregroundStyle(Palette.orange)
              .padding(10).background(Palette.paper)
              .overlay(Rectangle().stroke(Palette.orange, lineWidth: 1))
              .rotationEffect(.degrees(8)).offset(x: 89, y: 96)
          }
          .frame(maxWidth: .infinity).frame(height: 253)
          VStack(spacing: 10) {
            Button {
              selectedLunch = LunchBook.all[store.nextIndex]
            } label: {
              HStack {
                Text(store.stars == 0 ? "Pack your first lunch" : "Continue the journey")
                Spacer()
                Image(systemName: "arrow.right")
              }.padding(.horizontal, 20)
            }
            .buttonStyle(PrimaryButton())
            .accessibilityIdentifier("Start lunch")
            Button {
              selectedLunch = LunchBook.daily()
            } label: {
              HStack(spacing: 9) {
                Image(systemName: "sun.max")
                Text("The daily parcel")
                Spacer()
                Text(store.best[LunchBook.daily().id] != nil ? "PACKED" : "TODAY")
                  .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                Image(systemName: "arrow.up.right")
              }.padding(.horizontal, 20)
            }.buttonStyle(PrimaryButton(light: true))
              .accessibilityIdentifier("Daily challenge")
          }
          HStack {
            Text("YOUR LITTLE JOURNEY").font(.system(size: 10, weight: .bold, design: .monospaced))
              .tracking(1.5)
            Spacer()
            Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Palette.orange)
            Text("\(store.stars) / 36").font(
              .system(size: 11, weight: .medium, design: .monospaced))
          }
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10
          ) {
            ForEach(LunchBook.all) { lunch in
              let unlocked = lunch.number <= store.nextIndex + 1
              Button {
                selectedLunch = lunch
              } label: {
                VStack(spacing: 5) {
                  if unlocked {
                    Text(String(format: "%02d", lunch.number))
                      .font(.system(size: 23, weight: .regular, design: .serif))
                  } else {
                    Image(systemName: "lock").font(.system(size: 16)).frame(height: 27)
                  }
                  HStack(spacing: 2) {
                    ForEach(0..<3) { star in
                      Image(systemName: star < (store.best[lunch.id] ?? 0) ? "star.fill" : "circle")
                        .font(.system(size: 6))
                    }
                  }.foregroundStyle(unlocked ? Palette.orange : Palette.muted.opacity(0.5))
                }
                .frame(maxWidth: .infinity).frame(height: 66)
                .background(
                  unlocked ? Palette.sage.opacity(0.25) : Palette.line.opacity(0.18),
                  in: RoundedRectangle(cornerRadius: 12))
              }
              .disabled(!unlocked)
              .accessibilityLabel(
                "Lunch \(lunch.number), \(lunch.title), \(unlocked ? "\(store.best[lunch.id] ?? 0) stars" : "locked")"
              )
              .accessibilityIdentifier("Lunch \(lunch.number)")
            }
          }
          Text("A small ritual for a quieter day.")
            .font(.system(size: 13, design: .serif)).italic()
            .foregroundStyle(Palette.muted).frame(maxWidth: .infinity).padding(.bottom, 12)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 26).padding(.top, 14)
      }
    }
  }
}

struct SettingsView: View {
  @Bindable var store: LunchStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      Form {
        Section("A little atmosphere") {
          Toggle("Packing sounds", isOn: $store.sound).accessibilityIdentifier("Packing sounds")
          Toggle("Gentle haptics", isOn: $store.haptics).accessibilityIdentifier("Gentle haptics")
        }
        Section {
          Text(
            "Your lunches and best ratings stay on this iPhone. Daily parcels change at midnight UTC."
          )
          Text(
            "A perfect lunch uses one placement per piece, without a guide. Undo is always free.")
        } header: {
          Text("Packed with care")
        }
        Section {
          Text("Bento Circuit · Volume 01").font(.system(.body, design: .serif))
          Text("No clocks to race. Your move budget is the train ticket.")
        }
      }
      .navigationTitle("Make yourself at home")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    .presentationDetents([.medium, .large])
  }
}
