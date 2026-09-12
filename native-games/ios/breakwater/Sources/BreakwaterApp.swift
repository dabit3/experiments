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
    .font(.system(.body))
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
      let nextChart = HarborChart.campaign[min(3, model.unlocked - 1)]
      ZStack {
        Image("HarborPortrait")
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
          .clipped()
          .mask(
            LinearGradient(
              stops: [
                .init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                .init(color: .black, location: 1),
              ], startPoint: .top, endPoint: .bottom)
          )
          .offset(y: geometry.size.height * 0.02 + max(0, 720 - geometry.size.height) * 0.25)
          .accessibilityHidden(true)
        HarborAtmosphere()
          .allowsHitTesting(false)
        LinearGradient(
          stops: [
            .init(color: HarborPalette.ink.opacity(0.55), location: 0),
            .init(color: .clear, location: 0.25),
            .init(color: .clear, location: 0.50),
            .init(color: HarborPalette.ink.opacity(0.85), location: 0.70),
            .init(color: HarborPalette.ink, location: 0.89),
          ],
          startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: HarborSpacing.row) {
            RescueSeal().frame(width: 36, height: 36)
              .foregroundStyle(HarborPalette.brass)
              .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
              Text("Breakwater").font(HarborType.brand)
                .accessibilityAddTraits(.isHeader)
              Text("Coastal rescue").font(HarborType.label)
                .foregroundStyle(HarborPalette.muted)
            }
            Spacer()
            iconButton("slider.horizontal.3", label: "Settings", id: "settings") { settings = true }
          }
          .padding(.top, 8)
          Spacer()
          VStack(alignment: .leading, spacing: HarborSpacing.row) {
            HStack {
              eyebrow("Rescue \(nextChart.chapter) of 4")
              Spacer()
              Text(model.best[nextChart.id].map { "Best \($0)" } ?? "Not yet rescued")
                .font(HarborType.label)
                .foregroundStyle(HarborPalette.muted)
            }
            VStack(alignment: .leading, spacing: 5) {
              Text(nextChart.name).font(HarborType.title)
                .accessibilityAddTraits(.isHeader)
              Text(
                "\(nextChart.boats.count) boats · "
                  + (nextChart.currents.isEmpty ? "Calm water" : "Tidal currents")
              )
              .font(HarborType.body)
              .foregroundStyle(HarborPalette.muted)
            }
            primaryButton(
              "Plot rescue route", icon: "arrow.right",
              id: "beginRescue"
            ) {
              start(nextChart)
            }
            HStack(spacing: 12) {
              Button {
                charts = true
              } label: {
                Text("Rescue charts")
                  .frame(maxWidth: .infinity, minHeight: 48)
              }
              .accessibilityIdentifier("rescueCharts")
              Rectangle().fill(HarborPalette.separator).frame(width: 1, height: 22)
              Button {
                start(.daily(seed: HarborChart.dateSeed(), shift: 0))
              } label: {
                Text("Daily harbor")
                  .frame(maxWidth: .infinity, minHeight: 48)
              }
              .accessibilityIdentifier("dailyHarbor")
            }
            .font(HarborType.body.weight(.medium))
            .buttonStyle(HarborPressStyle())
            .foregroundStyle(HarborPalette.ivory)
          }
          .padding(.bottom, 12)
        }
        .padding(.horizontal, HarborSpacing.page)
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
            model.chart.dailySeed.map { "\($0) · Watch \(model.chart.shift + 1)" }
              ?? "Rescue \(model.chart.chapter) of 4")
          Text(model.chart.name).font(HarborType.title)
            .fixedSize(horizontal: false, vertical: true)
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
        HStack(spacing: 5) {
          ForEach(model.chart.boats.indices, id: \.self) { index in
            Image(
              systemName: model.convoy.contains(where: { $0.index == index })
                ? "smallcircle.filled.circle.fill" : "circle"
            )
            .foregroundStyle(
              model.convoy.contains(where: { $0.index == index })
                ? HarborPalette.brass : HarborPalette.muted
            )
            .font(.system(size: 10))
            .accessibilityHidden(true)
          }
          Text("\(model.convoy.count)/\(model.chart.boats.count) rescued")
            .font(HarborType.instrument)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.convoy.count) of \(model.chart.boats.count) boats rescued")
        Spacer()
        HStack(spacing: 7) {
          HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<8) { index in
              Rectangle()
                .fill(
                  Double(index) / 8 < model.remaining / model.chart.fuel
                    ? HarborPalette.brass : HarborPalette.muted.opacity(0.2)
                )
                .frame(width: 2, height: index % 3 == 0 ? 11 : 7)
            }
          }.accessibilityHidden(true)
          Text(
            "\(model.remaining < 100 ? "Low fuel" : "Fuel") "
              + "\(Int(model.phase == .plotting ? model.chart.fuel : model.remaining))"
          )
          .font(HarborType.instrument)
          .foregroundStyle(model.remaining < 100 ? HarborPalette.coral : HarborPalette.brass)
        }
      }
      .padding(.horizontal, HarborSpacing.page)
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
        .animation(reducedMotion ? nil : .easeOut(duration: 0.35), value: model.resultReady)
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
          Text("Route and fuel saved while paused.")
            .font(HarborType.label)
            .foregroundStyle(HarborPalette.muted)
        } else {
          if model.resultReady {
            resultControls
          } else {
            VStack(spacing: HarborSpacing.detail) {
              Text("Docking the convoy…")
                .font(HarborType.body)
                .foregroundStyle(HarborPalette.brass)
            }
          }
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(minHeight: 120)
    }
  }

  private var controls: some View {
    VStack(spacing: 2) {
      HStack {
        Text(
          model.phase == .sailing
            ? (model.inCurrent
              ? "Current pushing the tow."
              : (model.allRescued
                ? "All rescued. Returning to harbor." : "Tug following your route."))
            : (model.route.count > 1
              ? (model.routeFits ? "Route " : "Over budget: ")
                + "\(Int(model.plottedLength)) / \(Int(model.chart.fuel)) fuel"
              : "Draw from the tug to every boat, then HOME.")
        )
        .font(HarborType.label)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(
          !model.routeFits && model.phase == .plotting ? HarborPalette.coral : HarborPalette.muted)
        Spacer(minLength: 0)
        if model.phase == .plotting {
          Button {
            model.showGuide.toggle()
          } label: {
            Image(systemName: model.showGuide ? "eye.fill" : "eye")
              .frame(width: HarborSpacing.hitTarget, height: HarborSpacing.hitTarget)
              .background(
                model.showGuide ? HarborPalette.brass.opacity(0.18) : .clear,
                in: RoundedRectangle(cornerRadius: 6)
              )
              .foregroundStyle(model.showGuide ? HarborPalette.brass : HarborPalette.ivory)
          }
          .buttonStyle(HarborPressStyle())
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
        }
      } else {
        HStack {
          ProgressView(value: model.remaining, total: model.chart.fuel)
            .tint(HarborPalette.brass)
            .accessibilityLabel("Fuel remaining")
          Button("Restart") { model.reset(keepRoute: true) }
            .font(HarborType.label)
            .frame(width: 80, height: 46)
            .accessibilityIdentifier("restartVoyage")
        }
      }
    }
    .padding(.horizontal, HarborSpacing.page)
    .padding(.vertical, HarborSpacing.detail)
  }

  private var pauseOverlay: some View {
    ZStack {
      HarborPalette.ink.opacity(0.87)
      VStack(spacing: HarborSpacing.section) {
        Text("Voyage paused")
          .font(HarborType.title)
        primaryButton("Resume voyage", icon: "play.fill", id: "resumeVoyage") { model.resume() }
        Button("Redraw this route") { model.reset() }
          .frame(minHeight: 44).accessibilityIdentifier("pauseRedraw")
      }.padding(30)
    }
  }

  private var resultOverlay: some View {
    VStack {
      Spacer()
      VStack(alignment: .leading, spacing: HarborSpacing.row) {
        Text(model.chart.name).font(HarborType.label)
          .foregroundStyle(HarborPalette.onPaper)
        Text(model.phase == .won ? "\(model.convoy.count) boats home" : "Rescue interrupted")
          .font(HarborType.title)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("resultTitle")
        if model.phase == .won {
          Rectangle().fill(HarborPalette.ink.opacity(0.2)).frame(height: 1)
          HStack(alignment: .firstTextBaseline, spacing: 26) {
            resultMetric("\(model.score)", label: "Points")
            resultMetric("\(Int(model.remaining))", label: "Fuel left")
            Spacer(minLength: 0)
          }
          Text(
            model.chart.dailySeed.map { "Seed \($0) · Watch \(model.chart.shift + 1)" }
              ?? (model.chart.chapter == 4
                ? "All four rescue charts available"
                : "Rescue \(model.chart.chapter + 1) available")
          )
          .font(HarborType.label)
          .foregroundStyle(HarborPalette.onPaper)
        } else {
          Text(model.failure)
            .font(HarborType.body)
            .foregroundStyle(HarborPalette.onPaper)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(HarborSpacing.page)
      .foregroundStyle(HarborPalette.ink)
      .background(HarborPalette.ivory, in: RoundedRectangle(cornerRadius: 3))
      .overlay(alignment: .top) {
        Rectangle().fill(model.phase == .won ? HarborPalette.water : HarborPalette.coral)
          .frame(height: 3).padding(.horizontal, HarborSpacing.page)
      }
      .shadow(color: HarborPalette.ink.opacity(0.5), radius: 20, y: 10)
      .padding(18)
    }
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }

  private var resultControls: some View {
    VStack(spacing: 6) {
      if model.phase == .won {
        HStack(spacing: 12) {
          Button {
            share()
          } label: {
            Label("Share", systemImage: "square.and.arrow.up")
              .font(HarborType.label)
              .frame(minWidth: 78, minHeight: HarborSpacing.control)
          }
          .buttonStyle(HarborPressStyle())
          .accessibilityLabel("Share harbor postcard")
          .accessibilityIdentifier("sharePostcard")
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
        Button("Replay rescue") { model.reset() }
          .font(HarborType.label).frame(minHeight: HarborSpacing.hitTarget)
          .accessibilityIdentifier("replay")
      } else {
        primaryButton("Edit route & retry", icon: "pencil.tip", id: "retry") {
          model.reset(keepRoute: true)
        }
        Button("Clear route & retry") { model.reset() }
          .font(HarborType.label).frame(minHeight: HarborSpacing.hitTarget)
          .accessibilityIdentifier("cleanRetry")
      }
    }
    .padding(.horizontal, HarborSpacing.page)
    .padding(.top, 12)
    .padding(.bottom, 2)
  }

  private var tutorialSheet: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: HarborSpacing.section) {
          Text("Bring every boat home")
            .font(HarborType.title)
          tutorialRow(
            "01", title: "Draw the way home",
            text:
              "Start at the coral tug. Draw through each numbered boat and finish in the HOME ring. You can also tap to add straight waypoints."
          )
          tutorialRow(
            "02", title: "Leave room for the tow",
            text:
              "Keep clear of reefs and shores. Arrows show currents that push the tug sideways. Leave room for every boat following on a rope."
          )
          tutorialRow(
            "03", title: "Make the crossing",
            text:
              "Use Undo or Clear to edit your route. Keep it within the fuel budget, then launch the tug. You can pause or retry the rescue."
          )
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "eye")
            Text("Chart assist shows a suggested route. Trace it yourself to learn the crossing.")
              .font(HarborType.body)
          }
          .foregroundStyle(HarborPalette.brass)
          primaryButton("Start plotting", icon: "arrow.right", id: "tutorialDone") {
            tutorial = false
          }
        }.padding(HarborSpacing.page)
      }
      .background(HarborPalette.ink)
      .navigationTitle("How to play")
      .navigationBarTitleDisplayMode(.inline)
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
        Section("Sound & feedback") {
          Toggle("Harbor chimes", isOn: $model.sound).accessibilityIdentifier("soundToggle")
          Toggle("Haptic feedback", isOn: $model.haptics).accessibilityIdentifier("hapticsToggle")
        }
        Section {
          Text(
            "All progress stays on this iPhone. Daily charts change at midnight UTC. Your best completed watch today: \(model.dailyBest)."
          )
          Text("Reduced Motion follows your iPhone setting. Chimes respect Silent Mode.")
        } header: {
          Text("Progress & accessibility")
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
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
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
          Text("Complete a rescue to open the next chart. Replay any open chart to beat your best.")
            .font(HarborType.body)
            .foregroundStyle(HarborPalette.muted)
            .padding(.bottom, HarborSpacing.detail)
          ForEach(HarborChart.campaign.indices, id: \.self) { index in
            let chart = HarborChart.campaign[index]
            let open = index < model.unlocked
            Button {
              charts = false
              start(chart)
            } label: {
              HStack(spacing: HarborSpacing.row) {
                ChartPreview(chart: chart)
                  .frame(width: 54, height: 76)
                  .overlay(Rectangle().stroke(HarborPalette.brass.opacity(0.4), lineWidth: 0.5))
                  .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                  Text("Rescue \(index + 1)").font(HarborType.label)
                    .foregroundStyle(HarborPalette.muted)
                  Text(chart.name).font(HarborType.heading)
                  Text("\(chart.boats.count) boats · \(Int(chart.fuel)) fuel")
                    .font(HarborType.label)
                    .foregroundStyle(HarborPalette.muted)
                  Text(
                    open
                      ? (model.best[chart.id].map { "Best \($0) points" }
                        ?? "Ready for your first route")
                      : "Locked · Complete rescue \(index)"
                  )
                  .font(HarborType.label)
                  .foregroundStyle(open ? HarborPalette.brass : HarborPalette.muted)
                  .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: open ? "chevron.right" : "lock")
                  .font(HarborType.label)
                  .foregroundStyle(HarborPalette.brass)
                  .accessibilityHidden(true)
              }
              .padding(.vertical, HarborSpacing.section)
              .contentShape(Rectangle())
            }
            .buttonStyle(HarborPressStyle(dimWhenDisabled: false))
            .disabled(!open)
            .accessibilityIdentifier("chart\(index + 1)")
            Rectangle().fill(HarborPalette.separator).frame(height: 1)
          }
        }.padding(HarborSpacing.page)
      }
      .background(HarborPalette.ink)
      .navigationTitle("Rescue charts")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { charts = false }.accessibilityIdentifier("chartsDone")
        }
      }
    }
  }

  private func tutorialRow(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(number).font(HarborType.instrument).foregroundStyle(HarborPalette.brass)
        .padding(.top, 3).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 7) {
        Text(title).font(HarborType.heading)
        Text(text).font(HarborType.body).foregroundStyle(HarborPalette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func resultMetric(_ value: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(value).font(HarborType.score)
      Text(label).font(HarborType.label)
        .foregroundStyle(HarborPalette.onPaper)
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
    .font(HarborType.label)
    .foregroundStyle(HarborPalette.brass)
}

func iconButton(_ icon: String, label: String, id: String, action: @escaping () -> Void)
  -> some View
{
  Button(action: action) {
    Image(systemName: icon)
      .font(.system(size: 17, weight: .medium))
      .frame(width: HarborSpacing.hitTarget, height: HarborSpacing.hitTarget)
      .contentShape(Rectangle())
  }
  .buttonStyle(HarborPressStyle())
  .foregroundStyle(HarborPalette.ivory)
  .accessibilityLabel(label)
  .accessibilityIdentifier(id)
}

func primaryButton(_ title: String, icon: String, id: String, action: @escaping () -> Void)
  -> some View
{
  Button(action: action) {
    HStack {
      Text(title).font(HarborType.heading)
      Spacer()
      Image(systemName: icon).font(HarborType.body.weight(.semibold))
        .accessibilityHidden(true)
    }
    .padding(.horizontal, HarborSpacing.page)
    .padding(.vertical, HarborSpacing.row)
    .frame(minHeight: HarborSpacing.control)
    .background(HarborPalette.ivory, in: RoundedRectangle(cornerRadius: 6))
    .foregroundStyle(HarborPalette.ink)
    .contentShape(Rectangle())
  }
  .buttonStyle(HarborPressStyle())
  .accessibilityIdentifier(id)
}

struct HarborPostcard: View {
  @ObservedObject var model: HarborModel

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Breakwater").font(HarborType.brand)
          Text("Coastal rescue").font(HarborType.label)
        }
        Spacer()
        RescueSeal().frame(width: 48, height: 48)
          .foregroundStyle(HarborPalette.coral)
      }
      .padding(24)
      .foregroundStyle(HarborPalette.ink)
      HarborSea(model: model, postcard: true).frame(height: 455)
        .clipped()
        .overlay(Rectangle().stroke(HarborPalette.ink.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 14)
      VStack(alignment: .leading, spacing: 9) {
        Text("\(model.convoy.count) boats home").font(HarborType.title)
        Text("\(model.chart.name) · \(model.score) points")
          .font(HarborType.body.weight(.semibold))
        Text(
          model.chart.dailySeed.map { "Seed \($0) · Watch \(model.chart.shift + 1)" }
            ?? "Rescue \(model.chart.chapter) of 4 · \(Int(model.remaining)) fuel remaining"
        )
        .font(HarborType.label)
        .foregroundStyle(HarborPalette.onPaper)
        StitchRule().stroke(
          HarborPalette.ink.opacity(0.25),
          style: StrokeStyle(lineWidth: 1, dash: [2, 5])
        ).frame(height: 1).padding(.top, 9)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .foregroundStyle(HarborPalette.ink)
    }
    .frame(width: 390)
    .background(HarborPalette.ivory)
    .environment(\.dynamicTypeSize, .large)
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
