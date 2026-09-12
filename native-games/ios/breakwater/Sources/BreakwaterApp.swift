import LinkPresentation
import SwiftUI
import UIKit

@main
struct BreakwaterApp: App {
  var body: some Scene {
    WindowGroup {
      BreakwaterView()
        .preferredColorScheme(.dark)
        .tint(HarborPalette.brass)
    }
  }
}

struct BreakwaterView: View {
  @StateObject private var model = HarborModel()
  @State private var inGame = false
  @State private var settings = false
  @State private var charts = false
  @State private var tutorial = false
  @State private var shareImage: UIImage?
  @State private var sharing = false
  @State private var shareFailed = false
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      HarborPalette.ink.ignoresSafeArea()
      if inGame { voyage } else { home }
    }
    .font(.system(.body, design: .rounded))
    .foregroundStyle(HarborPalette.ivory)
    .onReceive(timer) { _ in
      if scenePhase == .active { model.step(1.0 / 30) }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { model.pause() }
    }
    .sheet(isPresented: $settings) { settingsSheet }
    .sheet(isPresented: $charts) { chartsSheet }
    .sheet(isPresented: $tutorial) { tutorialSheet }
    .sheet(isPresented: $sharing) {
      if let shareImage {
        HarborShare(
          image: shareImage,
          text: "BREAKWATER · \(model.convoy.count) boats home · \(model.score) points"
            + (model.chart.dailySeed.map { " · Daily seed \($0)" } ?? " · \(model.chart.name)"))
      }
    }
    .alert("Postcard unavailable", isPresented: $shareFailed) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Your result is saved. Please try sharing again.")
    }
  }

  private var home: some View {
    GeometryReader { geometry in
      ZStack {
        HarborSea(model: model, decorative: true)
          .frame(width: geometry.size.width, height: geometry.size.height * 0.76)
          .offset(y: geometry.size.height * 0.04)
        LinearGradient(
          stops: [
            .init(color: HarborPalette.ink, location: 0),
            .init(color: HarborPalette.ink.opacity(0.7), location: 0.17),
            .init(color: .clear, location: 0.4),
            .init(color: HarborPalette.ink.opacity(0.2), location: 0.66),
            .init(color: HarborPalette.ink, location: 0.89),
          ],
          startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            eyebrow("A SMALL HARBOR. A BIG RESCUE.")
            Spacer()
            iconButton("slider.horizontal.3", label: "Settings", id: "settings") { settings = true }
          }
          .padding(.top, 8)
          Text("Breakwater")
            .font(
              .system(size: min(geometry.size.width * 0.133, 62), weight: .regular, design: .serif)
            )
            .tracking(-2.5)
            .padding(.top, 12)
            .accessibilityAddTraits(.isHeader)
          HStack(spacing: 8) {
            Rectangle().fill(HarborPalette.brass).frame(width: 26, height: 1)
            Text("Bring every boat home.")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(HarborPalette.muted)
          }.padding(.top, 9)
          Spacer()
          VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
              VStack(alignment: .leading, spacing: 5) {
                eyebrow("THE RESCUE CHARTS")
                Text("\(min(model.unlocked, 4)) / 4 harbors open")
                  .font(.system(size: 13))
                  .foregroundStyle(HarborPalette.muted)
              }
              Spacer()
              Text("EST. 2026")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(HarborPalette.brass.opacity(0.6))
            }
            primaryButton(
              model.hasLearned ? "Return to sea" : "Begin the rescue", icon: "arrow.up.right",
              id: "beginRescue"
            ) {
              start(HarborChart.campaign[min(3, model.unlocked - 1)])
            }
            HStack(spacing: 12) {
              Button {
                charts = true
              } label: {
                Label("Rescue charts", systemImage: "map")
                  .frame(maxWidth: .infinity, minHeight: 48)
              }
              .accessibilityIdentifier("rescueCharts")
              Rectangle().fill(HarborPalette.ivory.opacity(0.15)).frame(width: 1, height: 22)
              Button {
                start(.daily(seed: HarborChart.dateSeed(), shift: 0))
              } label: {
                Label("Daily harbor", systemImage: "sun.horizon")
                  .frame(maxWidth: .infinity, minHeight: 48)
              }
              .accessibilityIdentifier("dailyHarbor")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(HarborPalette.ivory)
            Text("DRAW A ROUTE  ·  GATHER YOUR TOW  ·  FIND THE LIGHT")
              .font(.system(size: 8, weight: .medium, design: .monospaced))
              .tracking(0.8)
              .foregroundStyle(HarborPalette.muted.opacity(0.65))
              .frame(maxWidth: .infinity)
          }
          .padding(.bottom, 16)
        }
        .padding(.horizontal, 26)
      }
    }
  }

  private var voyage: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        iconButton("chevron.left", label: "Return to harbor menu", id: "home") {
          model.pause()
          inGame = false
          model.reset()
        }
        VStack(alignment: .leading, spacing: 4) {
          eyebrow(
            model.chart.dailySeed.map { "\($0) · WATCH \(model.chart.shift + 1)" }
              ?? "RESCUE CHART 0\(model.chart.chapter)")
          Text(model.chart.name).font(.system(size: 23, weight: .regular, design: .serif))
            .accessibilityAddTraits(.isHeader)
        }
        Spacer(minLength: 0)
        iconButton(
          model.phase == .sailing ? "pause" : "questionmark",
          label: model.phase == .sailing ? "Pause voyage" : "How to play", id: "pauseHelp"
        ) {
          if model.phase == .sailing { model.pause() } else { tutorial = true }
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 5)
      HStack(alignment: .center) {
        HStack(spacing: 6) {
          ForEach(model.chart.boats.indices, id: \.self) { index in
            Image(
              systemName: model.convoy.contains(where: { $0.index == index })
                ? "checkmark.circle.fill" : "circle"
            )
            .foregroundStyle(
              model.convoy.contains(where: { $0.index == index })
                ? HarborPalette.brass : HarborPalette.muted
            )
            .font(.system(size: 15))
          }
          Text("\(model.convoy.count)/\(model.chart.boats.count) TOW")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        Spacer()
        Text("FUEL \(Int(model.phase == .plotting ? model.chart.fuel : model.remaining))")
          .font(.system(size: 12, weight: .semibold, design: .monospaced))
          .foregroundStyle(model.remaining < 100 ? HarborPalette.coral : HarborPalette.brass)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      GeometryReader { geometry in
        ZStack {
          HarborSea(model: model)
          Color.clear.contentShape(Rectangle())
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  model.draw(
                    .init(
                      x: value.location.x / geometry.size.width * 360,
                      y: value.location.y / geometry.size.height * 520))
                }
                .onEnded { _ in model.endDrawing() }
            )
            .accessibilityLabel("Route drawing surface")
            .accessibilityHint(
              "Drag to trace. Tap to add straight waypoints. Use chart assist for a suggested route."
            )
            .accessibilityIdentifier("routeSurface")
          if model.phase == .paused { pauseOverlay }
          if model.resultReady { resultOverlay }
        }
        .clipped()
      }
      .overlay(alignment: .top) {
        Rectangle().fill(HarborPalette.brass.opacity(0.3)).frame(height: 1)
      }
      .overlay(alignment: .bottom) {
        Rectangle().fill(HarborPalette.brass.opacity(0.3)).frame(height: 1)
      }
      Group {
        if model.phase == .plotting || model.phase == .sailing {
          controls
        } else if model.phase == .paused {
          Text("The harbor can wait.")
            .font(.system(size: 13, design: .serif)).italic()
            .foregroundStyle(HarborPalette.muted)
        } else {
          if model.resultReady {
            resultControls
          } else {
            VStack(spacing: 10) {
              eyebrow("THE LIGHT IS YOURS")
              Text("Bringing the little fleet alongside…")
                .font(.system(size: 15, design: .serif)).italic()
                .foregroundStyle(HarborPalette.brass)
            }
          }
        }
      }
      .frame(height: 120)
    }
  }

  private var controls: some View {
    VStack(spacing: 10) {
      HStack {
        Text(
          model.phase == .sailing
            ? (model.inCurrent
              ? "Tidal drift. Give the tow room."
              : (model.allRescued
                ? "All aboard. Follow the light." : "Easy now. Let the tow follow."))
            : (model.route.count > 1
              ? "Route \(Int(model.plottedLength)) / \(Int(model.chart.fuel)) fuel"
              : "Trace from the tug. Visit every beacon.")
        )
        .font(.system(size: 12))
        .foregroundStyle(
          !model.routeFits && model.phase == .plotting ? HarborPalette.coral : HarborPalette.muted)
        Spacer(minLength: 0)
        if model.phase == .plotting {
          Button {
            model.showGuide.toggle()
          } label: {
            Image(systemName: model.showGuide ? "eye.fill" : "eye")
              .frame(width: 44, height: 30)
              .background(
                model.showGuide ? HarborPalette.brass.opacity(0.18) : .clear,
                in: Capsule()
              )
              .foregroundStyle(model.showGuide ? HarborPalette.brass : HarborPalette.ivory)
          }
          .accessibilityLabel(model.showGuide ? "Hide chart assist" : "Show chart assist")
          .accessibilityIdentifier("chartAssist")
        }
      }
      if model.phase == .plotting {
        HStack(spacing: 10) {
          iconButton("arrow.uturn.backward", label: "Undo last stroke", id: "undoRoute") {
            model.undo()
          }
          .disabled(model.route.count < 2)
          iconButton("trash", label: "Clear route", id: "clearRoute") { model.clear() }
            .disabled(model.route.count < 2)
          primaryButton("Launch tug", icon: "arrow.up.right", id: "launchTug") { model.launch() }
            .disabled(!model.canLaunch)
            .opacity(model.canLaunch ? 1 : 0.45)
        }
      } else {
        HStack {
          ProgressView(value: model.remaining, total: model.chart.fuel)
            .tint(HarborPalette.brass)
            .accessibilityLabel("Fuel remaining")
          Button("Restart") { model.reset(keepRoute: true) }
            .font(.system(size: 13, weight: .semibold))
            .frame(width: 80, height: 46)
            .accessibilityIdentifier("restartVoyage")
        }
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 10)
    .padding(.bottom, 12)
  }

  private var pauseOverlay: some View {
    ZStack {
      HarborPalette.ink.opacity(0.87)
      VStack(spacing: 22) {
        eyebrow("AT ANCHOR")
        Text("A moment of calm.")
          .font(.system(size: 32, design: .serif))
        primaryButton("Resume voyage", icon: "play.fill", id: "resumeVoyage") { model.resume() }
        Button("Redraw this route") { model.reset() }
          .frame(minHeight: 44).accessibilityIdentifier("pauseRedraw")
      }.padding(30)
    }
  }

  private var resultOverlay: some View {
    VStack {
      Spacer()
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          eyebrow(model.phase == .won ? "SAFE IN THE HARBOR" : "A LESSON FROM THE SEA")
          Spacer()
          Image(systemName: model.phase == .won ? "sun.max" : "water.waves")
            .foregroundStyle(HarborPalette.brass)
        }
        Text(model.phase == .won ? "Every light, home." : "Try another line.")
          .font(.system(size: 31, weight: .regular, design: .serif))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
          .accessibilityIdentifier("resultTitle")
        if model.phase == .won {
          HStack(alignment: .firstTextBaseline, spacing: 26) {
            resultMetric("\(model.convoy.count)", label: "BOATS RESCUED")
            resultMetric("\(model.score)", label: "POINTS")
            Spacer(minLength: 0)
          }
          Text(
            model.chart.dailySeed.map { "SEED \($0) · WATCH \(model.chart.shift + 1)" }
              ?? (model.chart.chapter == 4 ? "ALL FOUR HARBORS SAVED" : "NEXT CHART UNLOCKED")
          )
          .font(.system(size: 9, weight: .medium, design: .monospaced))
          .tracking(0.7)
          .foregroundStyle(HarborPalette.brass)
        } else {
          Text(model.failure)
            .font(.system(size: 13))
            .foregroundStyle(HarborPalette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(23)
      .background(HarborPalette.ink.opacity(0.96))
      .overlay(alignment: .top) { Rectangle().fill(HarborPalette.brass).frame(height: 2) }
      .padding(18)
    }
  }

  private var resultControls: some View {
    VStack(spacing: 6) {
      if model.phase == .won {
        HStack(spacing: 12) {
          iconButton("square.and.arrow.up", label: "Share harbor postcard", id: "sharePostcard") {
            share()
          }
          primaryButton(
            model.chart.chapter == 4
              ? "Daily harbor" : (model.chart.dailySeed == nil ? "Next rescue" : "Next watch"),
            icon: "arrow.right", id: "nextRescue"
          ) {
            if model.chart.chapter == 4 {
              model.select(.daily(seed: HarborChart.dateSeed(), shift: 0))
            } else {
              model.next()
            }
          }
        }
        Button("Sail this chart again") { model.reset() }
          .font(.system(size: 12)).frame(minHeight: 38).accessibilityIdentifier("replay")
      } else {
        primaryButton("Edit route & retry", icon: "pencil.tip", id: "retry") {
          model.reset(keepRoute: true)
        }
        Button("Start with a clean chart") { model.reset() }
          .font(.system(size: 12)).frame(minHeight: 38).accessibilityIdentifier("cleanRetry")
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 12)
    .padding(.bottom, 2)
  }

  private var tutorialSheet: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          eyebrow("YOUR FIRST WATCH")
          Text("One finger.\nA whole little fleet.")
            .font(.system(size: 36, design: .serif))
          tutorialRow(
            "01", title: "Draw the way home",
            text:
              "Begin at the coral tug. Trace through each numbered boat, then finish in the brass HOME ring. You can also tap to add straight waypoints."
          )
          tutorialRow(
            "02", title: "Leave room for the tow",
            text:
              "Ivory shores are solid. Arrows show currents that push your route sideways. Every boat follows on a rope; keep clear of reefs."
          )
          tutorialRow(
            "03", title: "Make the crossing",
            text:
              "Edit freely before launch. Undo a stroke or clear the chart. Watch your fuel, launch, and bring every boat home."
          )
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "eye")
            Text("Need a bearing? The eye reveals a suggested course. Trace over it yourself.")
              .font(.system(size: 13))
          }
          .foregroundStyle(HarborPalette.brass)
          primaryButton("I’m ready, captain", icon: "arrow.right", id: "tutorialDone") {
            tutorial = false
          }
        }.padding(26)
      }
      .background(HarborPalette.ink)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Close") { tutorial = false }.accessibilityIdentifier("closeTutorial")
        }
      }
    }
    .presentationDragIndicator(.visible)
  }

  private var settingsSheet: some View {
    NavigationStack {
      Form {
        Section("On board") {
          Toggle("Harbor chimes", isOn: $model.sound).accessibilityIdentifier("soundToggle")
          Toggle("Haptic feedback", isOn: $model.haptics).accessibilityIdentifier("hapticsToggle")
        }
        Section {
          Text(
            "All progress stays on this iPhone. Daily charts change at midnight UTC. Your best completed watch today: \(model.dailyBest)."
          )
          Text("Reduced Motion follows your iPhone setting. Chimes respect Silent Mode.")
        } header: {
          Text("A quieter kind of game")
        }
        Section {
          Button("How to play") {
            settings = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { tutorial = true }
          }.accessibilityIdentifier("settingsHelp")
        }
      }
      .scrollContentBackground(.hidden)
      .background(HarborPalette.ink)
      .navigationTitle("On board")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { settings = false }.accessibilityIdentifier("settingsDone")
        }
      }
    }
  }

  private var chartsSheet: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Four crossings.\nOne safe harbor.")
            .font(.system(size: 35, design: .serif)).padding(.bottom, 28)
          ForEach(HarborChart.campaign.indices, id: \.self) { index in
            let chart = HarborChart.campaign[index]
            let open = index < model.unlocked
            Button {
              charts = false
              start(chart)
            } label: {
              HStack(spacing: 18) {
                Text("0\(index + 1)")
                  .font(.system(size: 29, design: .serif))
                  .foregroundStyle(HarborPalette.brass)
                VStack(alignment: .leading, spacing: 6) {
                  Text(chart.name).font(.system(size: 20, design: .serif))
                  Text(
                    model.best[chart.id].map { "BEST \($0) · \(chart.boats.count) BOATS HOME" }
                      ?? (open ? chart.subtitle : "Complete the previous rescue")
                  )
                  .font(.system(size: 11))
                  .foregroundStyle(HarborPalette.muted)
                }
                Spacer()
                Image(systemName: open ? "arrow.up.right" : "lock")
              }
              .padding(.vertical, 22)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!open)
            .opacity(open ? 1 : 0.42)
            .accessibilityIdentifier("chart\(index + 1)")
            Divider().overlay(HarborPalette.muted.opacity(0.2))
          }
        }.padding(26)
      }
      .background(HarborPalette.ink)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { charts = false }.accessibilityIdentifier("chartsDone")
        }
      }
    }
  }

  private func tutorialRow(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(number).font(.system(size: 22, design: .serif)).foregroundStyle(HarborPalette.brass)
      VStack(alignment: .leading, spacing: 7) {
        Text(title).font(.system(size: 17, weight: .semibold))
        Text(text).font(.system(size: 14)).foregroundStyle(HarborPalette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func resultMetric(_ value: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(value).font(.system(size: 33, design: .serif))
      Text(label).font(.system(size: 8, weight: .semibold, design: .monospaced))
        .tracking(0.7).foregroundStyle(HarborPalette.muted)
    }
  }

  private func start(_ chart: HarborChart) {
    model.select(chart)
    inGame = true
    if !model.hasLearned { tutorial = true }
  }

  private func share() {
    let renderer = ImageRenderer(content: HarborPostcard(model: model))
    renderer.scale = 3
    guard let image = renderer.uiImage else {
      shareFailed = true
      return
    }
    shareImage = image
    sharing = true
  }
}

func eyebrow(_ text: String) -> some View {
  Text(text)
    .font(.system(size: 9, weight: .semibold, design: .monospaced))
    .tracking(1.6)
    .foregroundStyle(HarborPalette.brass)
}

func iconButton(_ icon: String, label: String, id: String, action: @escaping () -> Void)
  -> some View
{
  Button(action: action) {
    Image(systemName: icon)
      .font(.system(size: 17, weight: .medium))
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
  }
  .foregroundStyle(HarborPalette.ivory)
  .accessibilityLabel(label)
  .accessibilityIdentifier(id)
}

func primaryButton(_ title: String, icon: String, id: String, action: @escaping () -> Void)
  -> some View
{
  Button(action: action) {
    HStack {
      Text(title).font(.system(size: 15, weight: .semibold))
      Spacer()
      Image(systemName: icon).font(.system(size: 16, weight: .medium))
    }
    .padding(.horizontal, 20)
    .frame(height: 53)
    .background(HarborPalette.brass, in: RoundedRectangle(cornerRadius: 4))
    .foregroundStyle(HarborPalette.ink)
    .contentShape(Rectangle())
  }
  .accessibilityIdentifier(id)
}

struct HarborPostcard: View {
  @ObservedObject var model: HarborModel

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Breakwater").font(.system(size: 35, design: .serif))
          Text("A POSTCARD FROM THE HARBOR")
            .font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(1.7)
        }
        Spacer()
        Image(systemName: "sun.max").font(.system(size: 29))
      }
      .padding(24)
      .foregroundStyle(HarborPalette.ink)
      HarborSea(model: model, postcard: true).frame(height: 455)
      VStack(alignment: .leading, spacing: 9) {
        Text("Every light, home.").font(.system(size: 30, design: .serif))
        Text("\(model.convoy.count) BOATS RESCUED  /  \(model.score) POINTS")
          .font(.system(size: 11, weight: .semibold, design: .monospaced))
        Text(
          model.chart.dailySeed.map { "DAILY SEED \($0) · WATCH \(model.chart.shift + 1)" }
            ?? "\(model.chart.name.uppercased()) · RESCUE CHART 0\(model.chart.chapter)"
        )
        .font(.system(size: 9, design: .monospaced))
        .foregroundStyle(HarborPalette.ink.opacity(0.65))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .foregroundStyle(HarborPalette.ink)
    }
    .frame(width: 390)
    .background(HarborPalette.ivory)
  }
}

struct HarborShare: UIViewControllerRepresentable {
  let image: UIImage
  let text: String

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: [HarborPostcardItem(image: image, text: text), text],
      applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

final class HarborPostcardItem: NSObject, UIActivityItemSource {
  let image: UIImage
  let text: String

  init(image: UIImage, text: String) {
    self.image = image
    self.text = text
  }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController)
    -> Any
  {
    image
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    image
  }

  func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController)
    -> LPLinkMetadata?
  {
    let metadata = LPLinkMetadata()
    metadata.title = text
    metadata.imageProvider = NSItemProvider(object: image)
    metadata.iconProvider = NSItemProvider(object: image)
    return metadata
  }
}
