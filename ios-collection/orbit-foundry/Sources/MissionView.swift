import SwiftUI
import UIKit

struct MissionView: View {
  let mission: Mission
  @Bindable var store: FlightStore
  let close: () -> Void
  @State private var controller: FlightController
  @State private var showGuide = false
  @State private var showTutorial: Bool
  @State private var nextMission: Mission?
  @State private var confirmLeave = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var typeSize

  init(mission: Mission, store: FlightStore, close: @escaping () -> Void) {
    self.mission = mission
    self.store = store
    self.close = close
    _controller = State(initialValue: FlightController(mission: mission))
    _showTutorial = State(initialValue: mission.id == 0 && store.record(for: 0) == nil)
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        header.padding(.horizontal, 22)
        HStack {
          HStack(spacing: 7) {
            Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(Palette.cyan)
            Text("\(controller.flight?.collected.count ?? 0) / \(mission.beacons.count) BEACONS")
          }
          Spacer()
          Text(String(format: "FLIGHT %02d", controller.attempts + (controller.isReady ? 1 : 0)))
        }
        .font(.system(.caption2, design: .monospaced)).tracking(1.2)
        .foregroundStyle(Palette.muted).padding(.horizontal, 25).padding(.top, 18)
        ZStack {
          FlightCanvas(controller: controller, reduceMotion: reduceMotion) {
            controller.aim(toward: $0)
          }
          if let outcome = controller.flight?.outcome, outcome != .flying {
            resultPanel(outcome).padding(22)
          }
        }.frame(maxHeight: .infinity)
        controls.padding(.horizontal, 22).padding(.bottom, 12)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .background(Palette.background.ignoresSafeArea())
    .foregroundStyle(Palette.ivory)
    .sheet(isPresented: $showTutorial) { tutorial }
    .sheet(isPresented: $showGuide) { guide }
    .confirmationDialog("Leave this flight?", isPresented: $confirmLeave, titleVisibility: .visible)
    {
      Button("Return to observatory") { close() }
      Button("Keep flying", role: .cancel) {}
    } message: {
      Text("This flight's launches will not count toward a best score.")
    }
    .fullScreenCover(item: $nextMission) { next in
      MissionView(mission: next, store: store, close: close)
    }
    .task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(16))
        guard !Task.isCancelled else { break }
        if !confirmLeave {
          let count = controller.flight?.collected.count ?? 0
          controller.tick()
          if (controller.flight?.collected.count ?? 0) > count { feedback(.success) }
          if controller.flight?.outcome == .docked && !controller.savedResult {
            store.complete(
              mission.id, attempts: controller.attempts,
              seconds: controller.flight?.elapsed ?? 0, guided: controller.guided)
            controller.savedResult = true
            feedback(.success)
          }
        }
      }
    }
  }

  private var header: some View {
    HStack(spacing: 8) {
      Button {
        if controller.isFlying { confirmLeave = true } else { close() }
      } label: {
        Image(systemName: "arrow.left").frame(width: 44, height: 48)
      }.accessibilityLabel("Return to observatory")
      VStack(alignment: .leading, spacing: 4) {
        Engraving(text: "Mission \(mission.number)", color: Palette.copper)
        Text(mission.name).font(.system(.title3, design: .rounded).weight(.medium))
      }
      Spacer(minLength: 2)
      Button {
        controller.reset()
      } label: {
        Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 48)
      }.accessibilityLabel("Restart flight")
    }.padding(.top, 5)
  }

  private var controls: some View {
    VStack(spacing: 12) {
      if controller.isReady {
        HStack {
          Engraving(
            text: controller.isAiming ? "Trajectory live" : "Set your trajectory",
            color: Palette.cyan)
          Spacer()
          Button {
            showGuide = true
          } label: {
            Label("Flight guide", systemImage: "sparkle")
              .font(.caption).foregroundStyle(Palette.copper).padding(.vertical, 10)
          }
        }
        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "BEARING  %+.0f°", controller.angle))
              .font(.system(.caption2, design: .monospaced)).foregroundStyle(Palette.muted)
            Slider(value: $controller.angle, in: -80...80, step: 0.5)
              .accessibilityLabel("Bearing").accessibilityValue("\(Int(controller.angle)) degrees")
          }
          VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "THRUST  %.0f", controller.thrust))
              .font(.system(.caption2, design: .monospaced)).foregroundStyle(Palette.muted)
            Slider(value: $controller.thrust, in: 55...155, step: 1)
              .accessibilityLabel("Thrust").accessibilityValue("\(Int(controller.thrust))")
          }
        }
        Button {
          controller.launch()
          store.registerLaunch()
          feedback(.success)
        } label: {
          HStack {
            Image(systemName: "location.north.fill")
            Text("Launch probe")
          }
        }.buttonStyle(InstrumentButton())
      } else if controller.isFlying {
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Engraving(text: "Probe in flight", color: Palette.cyan)
            Text("Gravity has the controls.").font(.subheadline).foregroundStyle(Palette.muted)
          }
          Spacer()
          Text(String(format: "%.1f s", controller.flight?.elapsed ?? 0))
            .font(.system(.title2, design: .monospaced)).foregroundStyle(Palette.ivory)
        }.padding(.vertical, 14)
        Button("Abort & re-aim") { controller.reset() }.buttonStyle(InstrumentButton(filled: false))
      } else {
        HStack {
          Image(systemName: "circle.dotted")
          Text("Every orbit teaches you something.").font(.footnote)
        }.foregroundStyle(Palette.muted).padding(.vertical, 14)
      }
    }
  }

  private func resultPanel(_ outcome: FlightOutcome) -> some View {
    let won = outcome == .docked
    let title: String
    if case .failed(let reason) = outcome {
      title = reason
    } else {
      title = "A perfect rendezvous."
    }
    return VStack(spacing: 20) {
      ZStack {
        Circle().stroke(Palette.copper.opacity(0.4), lineWidth: 1).frame(width: 86, height: 86)
        Circle().stroke(Palette.cyan.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
          .frame(width: 106, height: 106)
        Image(systemName: won ? "checkmark" : "arrow.uturn.backward")
          .font(.system(size: 28, weight: .light)).foregroundStyle(
            won ? Palette.cyan : Palette.copper)
      }.padding(.top, 6)
      Engraving(
        text: won ? "All signals received" : "Flight ended",
        color: won ? Palette.cyan : Palette.copper)
      Text(title).font(.system(.largeTitle, design: .serif)).multilineTextAlignment(.center)
      if won {
        HStack(spacing: 12) {
          ForEach(0..<3) { index in
            Image(
              systemName: index < (controller.attempts == 1 ? 3 : controller.attempts <= 3 ? 2 : 1)
                ? "star.fill" : "star"
            )
            .foregroundStyle(Palette.copper)
          }
        }.accessibilityLabel(
          "\(controller.attempts == 1 ? 3 : controller.attempts <= 3 ? 2 : 1) stars")
        Text(
          "\(controller.attempts) \(controller.attempts == 1 ? "launch" : "launches")  ·  \(String(format: "%.1f", controller.flight?.elapsed ?? 0)) seconds\(controller.guided ? "  ·  Guided" : "")"
        )
        .font(.caption).foregroundStyle(Palette.muted)
        if mission.id < 7 {
          Button {
            nextMission = Mission.all[mission.id + 1]
          } label: {
            Text("Next: \(Mission.all[mission.id + 1].name)")
          }.buttonStyle(InstrumentButton())
        } else {
          Text("The atlas is yours. All eight missions complete.").font(.subheadline)
            .multilineTextAlignment(.center)
          Button("Return to observatory", action: close).buttonStyle(InstrumentButton())
        }
      } else {
        Text(
          "Adjust your bearing or thrust. Follow the dotted arc through every cyan beacon before docking."
        )
        .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Palette.muted)
        Button("Adjust & retry") { controller.reset() }.buttonStyle(InstrumentButton())
      }
      HStack(spacing: 20) {
        if won { Button("Fly again") { controller.reset() } }
        Button("Mission atlas", action: close)
      }.font(.subheadline).foregroundStyle(Palette.ivory).padding(.vertical, 8)
    }
    .padding(24)
    .background(Palette.panel.opacity(0.98), in: RoundedRectangle(cornerRadius: 28))
    .overlay {
      RoundedRectangle(cornerRadius: 28).stroke(Palette.copper.opacity(0.25), lineWidth: 1)
    }
  }

  private var tutorial: some View {
    VStack(alignment: .leading, spacing: 22) {
      Engraving(text: "Flight school / 01", color: Palette.copper)
      Text("Let gravity\nlend a hand.").font(.system(size: 38, weight: .regular, design: .serif))
      tutorialStep(
        "01", title: "Draw a flight",
        text:
          "Drag from the probe toward your destination. The dotted cyan arc predicts the real flight."
      )
      tutorialStep(
        "02", title: "Read the instruments",
        text: "Cyan diamonds are beacons. The ivory ring is your dock. Avoid the planet's surface.")
      tutorialStep(
        "03", title: "Release. Review. Launch.",
        text:
          "Lifting your finger keeps your aim. Tap Launch probe when you're ready. Your first course is already aligned."
      )
      Button("Ready for first light") { showTutorial = false }.buttonStyle(InstrumentButton())
    }
    .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(Palette.background).foregroundStyle(Palette.ivory)
    .presentationDetents([.large]).presentationDragIndicator(.visible)
  }
  private var guide: some View {
    VStack(alignment: .leading, spacing: 22) {
      Engraving(text: "Mission \(mission.number) / Flight guide", color: Palette.copper)
      Text("A nudge from\nmission control.").font(.system(.largeTitle, design: .serif))
      Text(mission.briefing).font(.body).foregroundStyle(Palette.muted)
      Text(
        "Align a proven course, then study its arc or fine-tune it yourself. This flight will be marked as guided."
      )
      .font(.subheadline).foregroundStyle(Palette.muted)
      Button("Align suggested course") {
        controller.useGuide()
        showGuide = false
      }.buttonStyle(InstrumentButton())
      Button("Keep my course") { showGuide = false }.frame(maxWidth: .infinity, minHeight: 44)
    }
    .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.background).foregroundStyle(Palette.ivory)
    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
  }
  private func tutorialStep(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.copper)
        .padding(.top, 4)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.headline)
        Text(text).font(.subheadline).foregroundStyle(Palette.muted)
      }
    }
  }
  private func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    if store.archive.haptics { UINotificationFeedbackGenerator().notificationOccurred(type) }
  }
}
