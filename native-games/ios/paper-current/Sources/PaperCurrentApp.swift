import AudioToolbox
import SwiftUI
import UIKit

@main
struct PaperCurrentApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .preferredColorScheme(.light)
        .tint(Ink.red)
    }
  }
}

enum Feedback {
  static func tap(success: Bool = false) {
    if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true {
      if success {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      } else {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      }
    }
    if UserDefaults.standard.bool(forKey: "sound") {
      AudioServicesPlaySystemSound(success ? 1025 : 1104)
    }
  }
}

struct MainButton: View {
  let title: String
  var icon = "arrow.right"
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 17, weight: .semibold))
        Spacer()
        Image(systemName: icon).font(.system(size: 16, weight: .semibold))
      }
      .foregroundStyle(Ink.cream)
      .padding(.horizontal, 22)
      .frame(minHeight: 58)
      .background(Ink.red, in: RoundedRectangle(cornerRadius: 6))
      .overlay(alignment: .bottom) {
        Rectangle().fill(Ink.night.opacity(0.2)).frame(height: 3).padding(.horizontal, 3)
      }
    }
    .buttonStyle(.plain)
  }
}

struct IconButton: View {
  let icon: String
  let label: String
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 19))
        .foregroundStyle(Ink.paper)
        .frame(width: 46, height: 46)
        .background(Ink.cream.opacity(0.07), in: Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(label)
  }
}

struct Eyebrow: View {
  let text: String
  var color = Ink.muted
  var body: some View {
    Text(text).font(.system(size: 10, weight: .bold, design: .monospaced))
      .tracking(2.5).foregroundStyle(color)
  }
}

struct RootView: View {
  @State private var selected: Int?
  @State private var showSettings = false
  @State private var showChapters = false
  @State private var refresh = UUID()
  private let store = ProgressStore()

  var body: some View {
    ZStack {
      Ink.night.ignoresSafeArea()
      if let selected {
        GameView(
          level: Level.all[selected],
          home: {
            self.selected = nil
            refresh = UUID()
          },
          next: {
            self.selected = min(selected + 1, Level.all.count - 1)
          }
        ).id(selected)
      } else {
        home.id(refresh)
      }
    }
    .sheet(isPresented: $showSettings) { SettingsView() }
    .sheet(isPresented: $showChapters) {
      ChapterView(store: store) {
        selected = $0
        showChapters = false
      }
    }
  }

  private var home: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          Eyebrow(text: "A SMALL BOAT. A BIG JOURNEY.")
          Spacer(minLength: 8)
          IconButton(icon: "slider.horizontal.3", label: "Settings") {
            showSettings = true
          }
        }.padding(.top, 6)
        VStack(alignment: .leading, spacing: 8) {
          Text("Paper\nCurrent")
            .font(Ink.title(geometry.size.height < 720 ? 59 : 70))
            .tracking(-3).lineSpacing(-10)
            .foregroundStyle(Ink.cream)
          HStack(spacing: 8) {
            Rectangle().fill(Ink.red).frame(width: 25, height: 2)
            Text("Letters find a way.")
              .font(Ink.title(18)).italic().foregroundStyle(Ink.muted)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        TownArt()
          .frame(maxHeight: .infinity)
          .padding(.horizontal, -16)
          .overlay(alignment: .topTrailing) {
            VStack(spacing: 3) {
              Image(systemName: "envelope").font(.system(size: 21, weight: .light))
              Text("POST\n01—10").font(.system(size: 9, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
            }
            .foregroundStyle(Ink.paper).padding(12)
            .overlay(
              Rectangle().strokeBorder(
                Ink.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            )
            .rotationEffect(.degrees(9)).padding(.top, 6).padding(.trailing, 10)
          }
        VStack(spacing: 15) {
          Text("Turn the canals. Open the locks.\nDeliver a little wonder.")
            .font(.system(size: 14)).lineSpacing(4)
            .foregroundStyle(Ink.paper).multilineTextAlignment(.center)
          MainButton(title: store.completed.isEmpty ? "Begin the journey" : "Continue the journey")
          {
            Feedback.tap()
            selected = store.unlocked
          }.accessibilityIdentifier("beginJourney")
          Button {
            showChapters = true
          } label: {
            HStack {
              Text("The letter collection")
              Spacer()
              Text("\(store.completed.count) / 10").monospacedDigit()
              Image(systemName: "arrow.up.right")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Ink.muted).frame(minHeight: 44)
          }.accessibilityIdentifier("chapters")
        }.padding(.bottom, 12)
      }.padding(.horizontal, 27)
    }
  }
}

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage("sound") private var sound = false
  @AppStorage("haptics") private var haptics = true
  var body: some View {
    NavigationStack {
      Form {
        Section("The atmosphere") {
          Toggle("Sound effects", isOn: $sound).accessibilityIdentifier("soundToggle")
          Toggle("Haptics", isOn: $haptics).accessibilityIdentifier("hapticsToggle")
        }
        Section("A slower kind of game") {
          Text(
            "Plan for as long as you like. The water rises only after you release the boat. Every letter can be delivered without hints."
          )
          Text(
            "Reduce Motion follows your iPhone’s accessibility setting. Progress is saved on this device."
          )
        }
        Section {
          Text(
            "An original paper town, drawn entirely in SwiftUI.\nNo accounts. No adverts. Just one small boat."
          )
          .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Quiet details")
      .toolbar { Button("Done") { dismiss() }.accessibilityIdentifier("closeSettings") }
    }.presentationDetents([.medium, .large])
  }
}

struct ChapterView: View {
  let store: ProgressStore
  let select: (Int) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          ForEach(Level.all) { level in
            Button {
              select(level.id)
            } label: {
              HStack(spacing: 16) {
                Text(String(format: "%02d", level.id + 1))
                  .font(Ink.title(28)).foregroundStyle(Ink.red)
                  .frame(width: 42)
                VStack(alignment: .leading, spacing: 5) {
                  Text(level.title).font(Ink.title(18)).foregroundStyle(Ink.night)
                  Text(
                    store.completed[String(level.id)].map { "Delivered · best \($0) moves" }
                      ?? (level.id <= store.unlocked
                        ? "Ready to sail" : "Deliver the previous letter")
                  )
                  .font(.system(size: 12)).foregroundStyle(Ink.blue)
                }
                Spacer()
                Image(systemName: level.id > store.unlocked ? "lock" : "arrow.right")
                  .foregroundStyle(Ink.blue)
              }.padding(.vertical, 19).padding(.horizontal, 22)
            }
            .disabled(level.id > store.unlocked)
            .opacity(level.id > store.unlocked ? 0.5 : 1)
            .accessibilityIdentifier("chapter\(level.id + 1)")
            Divider().padding(.horizontal, 22)
          }
        }
      }
      .background(Ink.paper)
      .navigationTitle("The letter collection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { Button("Done") { dismiss() } }
    }
  }
}
