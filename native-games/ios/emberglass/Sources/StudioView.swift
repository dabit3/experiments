import SwiftUI
import UIKit

struct StudioView: View {
  @StateObject private var studio = Studio()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var galleryOpen = false
  @State private var settingsOpen = false
  @State private var shareImage: UIImage?
  @State private var shareOpen = false
  @State private var previousTick = Date()
  @State private var reveal = false
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        StudioBackdrop(warm: studio.stage == .heat || studio.stage == .spin)
        VStack(spacing: 0) {
          navigation
          switch studio.stage {
          case .home: home(compact: geometry.size.height < 730)
          case .heat, .spin, .shape: play
          case .result: result(compact: geometry.size.height < 730)
          }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 12)
        if studio.tutorial { tutorial }
        if studio.paused { pause }
      }
      .foregroundStyle(Palette.cream)
    }
    .onReceive(timer) { date in
      let delta = date.timeIntervalSince(previousTick)
      previousTick = date
      studio.tick(delta: delta)
    }
    .onChange(of: scenePhase) { _, value in
      if value != .active { studio.suspend() }
      previousTick = Date()
    }
    .onChange(of: studio.stage) { _, stage in
      reveal = false
      if stage == .result {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 1.6)) { reveal = true }
      }
    }
    .sheet(isPresented: $galleryOpen) { gallery }
    .sheet(isPresented: $settingsOpen) { settings }
    .sheet(isPresented: $shareOpen) {
      if let shareImage, let piece = studio.result {
        ShareSheet(
          image: shareImage,
          text:
            "I made \(piece.commission.title) in Emberglass. \(piece.grade) · \(piece.score)/100. Made of fire. Finished by hand."
        )
      }
    }
  }

  private var navigation: some View {
    HStack {
      HStack(spacing: 8) {
        Image(systemName: "flame")
          .font(.system(size: 16, weight: .light))
          .foregroundStyle(Palette.ember)
        Text("E / G").font(.system(size: 13, weight: .medium, design: .serif)).tracking(3)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Emberglass studio")
      Spacer()
      if studio.stage.isPlaying {
        Text("\(studio.remaining)s").font(.system(size: 14, design: .monospaced))
          .foregroundStyle(Palette.muted)
          .contentTransition(.numericText())
        icon("pause", label: "Pause session", identifier: "pauseButton") { studio.suspend() }
      } else {
        icon("square.grid.2x2", label: "Open gallery", identifier: "galleryButton") {
          galleryOpen = true
        }
        icon("slider.horizontal.3", label: "Settings", identifier: "settingsButton") {
          settingsOpen = true
        }
      }
    }
    .frame(height: 54)
  }

  private func home(compact: Bool) -> some View {
    VStack(spacing: compact ? 10 : 16) {
      VStack(spacing: 8) {
        eyebrow("THE GLASSBLOWING STUDIO")
        Text("Emberglass")
          .font(.system(size: compact ? 44 : 49, weight: .regular, design: .serif))
          .tracking(-2)
        Text("Made of fire. Finished by hand.")
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
      }
      .padding(.top, compact ? 4 : 14)
      centerpiece(profile: studio.commission.radii, commission: studio.commission, molten: false)
        .frame(maxHeight: .infinity)
      VStack(spacing: 13) {
        HStack {
          eyebrow(
            "COMMISSION \(String(format: "%02d", studio.commission.rawValue + 1))",
            color: Palette.ember)
          Spacer()
          Text(studio.archive.best > 0 ? "BEST \(studio.archive.best)" : "FIRST FIRING")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(1).foregroundStyle(Palette.muted)
        }
        HStack {
          VStack(alignment: .leading, spacing: 5) {
            Text(studio.commission.title).font(.system(size: 27, design: .serif))
            Text(studio.commission.subtitle).font(.system(size: 12)).foregroundStyle(Palette.muted)
          }
          Spacer(minLength: 4)
          Button {
            let next = (studio.commission.rawValue + 1) % (studio.archive.unlocked + 1)
            studio.commission = Commission(rawValue: next) ?? .tide
            studio.feedback()
          } label: {
            Image(systemName: studio.archive.unlocked == 0 ? "lock" : "arrow.right")
              .font(.system(size: 15)).frame(width: 44, height: 44)
              .overlay(Circle().stroke(Palette.cream.opacity(0.22), lineWidth: 1))
          }
          .disabled(studio.archive.unlocked == 0)
          .accessibilityLabel(
            studio.archive.unlocked == 0
              ? "More commissions unlock at 55 points" : "Next commission"
          )
          .accessibilityIdentifier("nextCommissionButton")
        }
        primary("Enter the furnace", symbol: "arrow.up.right", identifier: "startButton") {
          studio.start()
        }
        HStack(spacing: 10) {
          Text("HEAT").foregroundStyle(Palette.ember)
          Text("—")
          Text("SPIN")
          Text("—")
          Text("SHAPE")
          Spacer()
          Text("~ 1 MIN")
        }
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .tracking(1.5).foregroundStyle(Palette.muted)
      }
    }
  }

  private func centerpiece(profile: [Double], commission: Commission, molten: Bool) -> some View {
    GeometryReader { geometry in
      TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || studio.paused)) {
        timeline in
        let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * 0.55
        ZStack(alignment: .bottom) {
          VStack(spacing: 0) {
            VesselArt(profile: profile, molten: molten, phase: phase, commission: commission)
              .frame(width: min(geometry.size.width * 0.74, geometry.size.height * 0.73))
              .padding(.bottom, -6)
            Plinth().frame(width: geometry.size.width * 0.74)
          }
          .padding(.bottom, 25)
          Text(molten ? "MOLTEN / WORK IN PROGRESS" : commission.collection)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(2).foregroundStyle(Palette.muted)
        }
      }
    }
  }

  private var play: some View {
    VStack(spacing: 14) {
      HStack(spacing: 5) {
        ForEach([Stage.heat, .spin, .shape], id: \.rawValue) { stage in
          Rectangle()
            .fill(stage == studio.stage ? Palette.ember : Palette.cream.opacity(0.15))
            .frame(height: 2)
        }
      }
      VStack(spacing: 7) {
        eyebrow(studio.stage.step, color: Palette.ember)
        Text(studio.stage.title).font(.system(size: 34, design: .serif)).tracking(-1)
        Text(instruction).font(.system(size: 13)).foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
      }
      .padding(.top, 10)
      if studio.stage == .shape {
        shaping
      } else {
        ZStack(alignment: .bottom) {
          centerpiece(profile: studio.commission.radii, commission: studio.commission, molten: true)
          Text(
            studio.stage == .heat
              ? "\(Int(studio.temperature * 900 + 500))°" : "\(Int(studio.rotation * 50 + 10)) RPM"
          )
          .font(.system(size: 20, weight: .light, design: .monospaced))
          .foregroundStyle(Palette.ember)
          .padding(.bottom, 50)
          .shadow(color: .black, radius: 5)
        }
      }
      stageControls
    }
  }

  private var instruction: String {
    switch studio.stage {
    case .heat: "Hold to warm. Release to cool. Follow the glow."
    case .spin: "Slide the dial into the moving balance window."
    case .shape: "Draw down the dotted right edge, from lip to base."
    default: ""
    }
  }

  private var shaping: some View {
    GeometryReader { geometry in
      let width = min(geometry.size.width * 0.90, geometry.size.height * 0.94)
      let height = geometry.size.height - 18
      let origin = (geometry.size.width - width) / 2
      let top = height * 0.09
      let step = height * 0.79 / 7
      ZStack {
        VesselArt(
          profile: studio.profile, molten: false,
          phase: reduceMotion ? 0 : studio.elapsed * 0.12, commission: studio.commission
        )
        .frame(width: width, height: height)
        .position(x: geometry.size.width / 2, y: height / 2)
        VesselShape(profile: studio.commission.radii)
          .stroke(Palette.cream.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
          .frame(width: width, height: height)
          .position(x: geometry.size.width / 2, y: height / 2)
        ForEach(0..<8) { index in
          let x = origin + width / 2 + width * 0.48 * studio.commission.radii[index]
          let y = top + Double(index) * step
          Circle()
            .fill(studio.touched.contains(index) ? Palette.mint : Palette.cream)
            .frame(width: 8, height: 8)
            .overlay(Circle().stroke(Palette.mint.opacity(0.2), lineWidth: 7))
            .position(x: x, y: y)
            .accessibilityHidden(true)
        }
        Text("LIP").position(x: geometry.size.width / 2 - 18, y: top - 15)
        Text("BASE").position(x: geometry.size.width / 2 - 18, y: top + 7 * step + 23)
      }
      .font(.system(size: 8, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          let index = Int(((value.location.y - top) / step).rounded())
          let radius = (value.location.x - geometry.size.width / 2) / (width * 0.48)
          studio.trace(index: index, radius: radius)
        }
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Vessel shaping canvas")
      .accessibilityHint(
        "Trace the eight dots down the right edge. With VoiceOver, use the guided shaping controls below."
      )
      .accessibilityIdentifier("shapingCanvas")
    }
  }

  @ViewBuilder
  private var stageControls: some View {
    VStack(spacing: 14) {
      HStack {
        eyebrow(studio.stage == .shape ? "FORM ACCURACY" : "LIVE PRECISION")
        Spacer()
        Text("\(studio.liveQuality)%")
          .font(.system(size: 13, weight: .medium, design: .monospaced))
          .foregroundStyle(studio.liveQuality >= 55 ? Palette.mint : Palette.ember)
      }
      if studio.stage == .heat {
        gauge(value: studio.temperature, target: studio.heatTarget)
        Text(studio.holding ? "HEATING  •  RELEASE TO COOL" : "HOLD TO HEAT")
          .font(.system(size: 12, weight: .semibold)).tracking(2)
          .frame(maxWidth: .infinity).frame(height: 58)
          .background(studio.holding ? Palette.ember : Palette.ember.opacity(0.13))
          .foregroundStyle(studio.holding ? Palette.background : Palette.ember)
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.ember.opacity(0.5)))
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0).onChanged { _ in
              studio.holding = true
            }.onEnded { _ in studio.holding = false }
          )
          .accessibilityElement()
          .accessibilityLabel(
            studio.holding ? "Heating, activate to cool" : "Hold to heat, activate to toggle"
          )
          .accessibilityAddTraits(.isButton)
          .accessibilityAction { studio.holding.toggle() }
          .accessibilityIdentifier("heatControl")
      } else if studio.stage == .spin {
        gauge(value: studio.rotation, target: studio.spinTarget)
        Slider(value: $studio.rotation, in: 0...1)
          .tint(Palette.ember)
          .accessibilityLabel("Rotation speed")
          .accessibilityValue(
            "\(Int(studio.rotation * 100)) percent. Target \(Int(studio.spinTarget * 100)) percent"
          )
          .accessibilityIdentifier("rotationSlider")
          .frame(height: 44)
        HStack {
          Text("SLOW")
          Spacer()
          Image(systemName: "arrow.left.and.right")
          Spacer()
          Text("FAST")
        }.font(.system(size: 9, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
      } else {
        HStack {
          Text("\(studio.touched.count) / 8 points traced")
            .font(.system(size: 12)).foregroundStyle(Palette.muted)
          Spacer()
          Button("Reset curve") {
            studio.profile = studio.commission.radii.map { $0 * 0.73 }
            studio.touched = []
          }
          .font(.system(size: 12)).foregroundStyle(Palette.cream)
          .frame(minHeight: 44)
          .accessibilityIdentifier("resetCurveButton")
        }
        primary("Cool & reveal", symbol: "sparkle", identifier: "finishButton") { studio.finish() }
        accessibleShaping
      }
    }
    .padding(.bottom, 5)
  }

  @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
  @State private var selectedPoint = 0

  @ViewBuilder
  private var accessibleShaping: some View {
    if voiceOver {
      Stepper("Point \(selectedPoint + 1)", value: $selectedPoint, in: 0...7)
      Slider(
        value: Binding(
          get: { studio.profile[selectedPoint] },
          set: { studio.trace(index: selectedPoint, radius: $0) }
        ), in: 0.18...0.94
      )
      .accessibilityLabel(
        "Shape point \(selectedPoint + 1). Target \(Int(studio.commission.radii[selectedPoint] * 100))"
      )
      .accessibilityValue("\(Int(studio.profile[selectedPoint] * 100))")
    }
  }

  private func gauge(value: Double, target: Double) -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(Palette.cream.opacity(0.10)).frame(height: 7)
        Capsule()
          .fill(Palette.mint.opacity(0.32))
          .overlay(Capsule().stroke(Palette.mint.opacity(0.7), lineWidth: 1))
          .frame(width: geometry.size.width * 0.20, height: 18)
          .offset(x: geometry.size.width * (target - 0.1))
        Capsule().fill(Palette.cream).frame(width: 4, height: 26)
          .shadow(color: .white.opacity(0.5), radius: 6)
          .offset(x: (geometry.size.width - 4) * value)
      }
      .frame(height: 26)
    }
    .frame(height: 26)
    .accessibilityLabel("Precision gauge")
    .accessibilityValue("\(Int(value * 100)), target \(Int(target * 100))")
  }

  @ViewBuilder
  private func result(compact: Bool) -> some View {
    if let piece = studio.result {
      VStack(spacing: compact ? 8 : 13) {
        eyebrow(
          piece.collected ? "A NEW PIECE FOR YOUR GALLERY" : "EVERY MASTER BEGINS WITH A STUDY",
          color: Palette.mint
        )
        .padding(.top, 8)
        Text(piece.collected ? "From fire, a jewel." : "Return to the fire.")
          .font(.system(size: compact ? 33 : 37, design: .serif)).tracking(-1)
        centerpiece(profile: piece.profile, commission: piece.commission, molten: false)
          .frame(maxHeight: .infinity)
          .scaleEffect(reveal || reduceMotion ? 1 : 0.86)
          .opacity(reveal || reduceMotion ? 1 : 0.2)
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 5) {
            eyebrow(piece.grade, color: Palette.mint)
            Text(piece.commission.title).font(.system(size: 26, design: .serif))
          }
          Spacer()
          Text("\(piece.score)").font(.system(size: 45, weight: .light, design: .serif))
          Text("/100").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
        }
        Rectangle().fill(Palette.cream.opacity(0.18)).frame(height: 1)
        HStack {
          metric("HEAT", value: piece.heat)
          Spacer()
          metric("BALANCE", value: piece.spin)
          Spacer()
          metric("FORM", value: piece.shape)
        }
        Text(resultAdvice(piece))
          .font(.system(size: 12)).foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center).frame(minHeight: 32)
        HStack(spacing: 12) {
          primary("Fire again", symbol: "arrow.clockwise", identifier: "retryButton") {
            studio.start()
          }
          Button {
            share(piece)
          } label: {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 19)).frame(width: 56, height: 56)
              .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.cream.opacity(0.3)))
          }
          .accessibilityLabel("Share finished vessel").accessibilityIdentifier("shareButton")
        }
        Button("Return to studio") { studio.home() }
          .font(.system(size: 12)).foregroundStyle(Palette.muted).frame(height: 38)
          .accessibilityIdentifier("homeButton")
      }
    }
  }

  private func resultAdvice(_ piece: GalleryPiece) -> String {
    if piece.collected {
      return piece.commission == .spire
        ? "Collected. Chase 90 to earn a Masterwork."
        : "Collected. Your next commission is unlocked."
    }
    if piece.shape < min(piece.heat, piece.spin) {
      return "Trace all eight points more closely. 55 earns a gallery piece."
    }
    return "Stay inside the glowing windows longer. 55 earns a gallery piece."
  }

  private func metric(_ title: String, value: Int) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      eyebrow(title)
      Text("\(value)%").font(.system(size: 17, design: .monospaced))
    }
  }

  private var tutorial: some View {
    ZStack {
      Palette.background.opacity(0.94).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 22) {
        Text(studio.stage == .heat ? "I" : studio.stage == .spin ? "II" : "III")
          .font(.system(size: 90, weight: .ultraLight, design: .serif))
          .foregroundStyle(Palette.ember)
        eyebrow("YOUR FIRST \(studio.stage.rawValue.uppercased())")
        Text(studio.stage.title).font(.system(size: 39, design: .serif))
        Text(tutorialCopy)
          .font(.system(size: 17)).lineSpacing(5).foregroundStyle(Palette.muted)
        Rectangle().fill(Palette.cream.opacity(0.2)).frame(height: 1)
        Text(
          studio.stage == .shape
            ? "Form is 44% of your final grade." : "This stage is 28% of your final grade."
        )
        .font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.mint)
        primary(
          "Begin \(studio.stage.rawValue)", symbol: "arrow.right",
          identifier: "tutorialContinueButton"
        ) {
          studio.dismissTutorial()
        }
      }
      .padding(32)
    }
    .accessibilityAddTraits(.isModal)
  }

  private var tutorialCopy: String {
    switch studio.stage {
    case .heat:
      "Hold the orange pad to raise the white temperature marker. Release to let it fall.\n\nKeep that marker inside the moving green window for 14 seconds."
    case .spin:
      "Slide the rotation dial left or right. Keep the white marker inside the moving green window.\n\nA steady hand gives the glass its symmetry."
    case .shape:
      "Trace the eight glowing dots along the right edge of the vessel. The left side mirrors your hand.\n\nYou have 26 seconds. Tap Cool & reveal when your curve is ready."
    default: ""
    }
  }

  private var pause: some View {
    ZStack {
      Palette.background.opacity(0.97).ignoresSafeArea()
      VStack(spacing: 23) {
        eyebrow("THE FIRE CAN WAIT", color: Palette.ember)
        Text("A moment of stillness.").font(.system(size: 31, design: .serif))
        primary("Resume", symbol: "play", identifier: "resumeButton") {
          previousTick = Date()
          studio.paused = false
        }
        Button("Restart commission") { studio.start() }
          .frame(height: 44).accessibilityIdentifier("restartButton")
        Button("Leave furnace") { studio.home() }
          .foregroundStyle(Palette.muted).frame(height: 44)
          .accessibilityIdentifier("leaveButton")
      }.padding(30)
    }
    .accessibilityAddTraits(.isModal)
  }

  private var gallery: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("The collection").font(.system(size: 36, design: .serif))
          Text("Your last 24 firings. Collect at 55. Master at 90.")
            .font(.system(size: 13)).foregroundStyle(Palette.muted)
          if studio.archive.pieces.isEmpty {
            VesselArt(profile: Commission.tide.radii, commission: .tide)
              .frame(height: 250).opacity(0.45)
            Text("A place for things you make.")
              .font(.system(size: 25, design: .serif))
            Text("Your first vessel is waiting in the fire.").foregroundStyle(Palette.muted)
          }
          ForEach(studio.archive.pieces) { piece in
            HStack(spacing: 24) {
              VesselArt(profile: piece.profile, commission: piece.commission)
                .frame(width: 84, height: 120)
              VStack(alignment: .leading, spacing: 9) {
                eyebrow(piece.collected ? piece.grade : "STUDY", color: Palette.mint)
                Text(piece.commission.title).font(.system(size: 24, design: .serif))
                Text(
                  "\(piece.score) / 100  ·  \(piece.date.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.muted)
              }
            }
            .accessibilityElement(children: .combine)
            Rectangle().fill(Palette.cream.opacity(0.12)).frame(height: 1)
          }
        }.padding(26)
      }
      .background(Palette.background)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { galleryOpen = false }.accessibilityIdentifier("closeGalleryButton")
        }
      }
    }
    .tint(Palette.cream)
    .presentationDragIndicator(.visible)
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section("In the studio") {
          Toggle("Haptic feedback", isOn: $studio.haptics).accessibilityIdentifier("hapticsToggle")
          Text(
            "A quiet studio. Emberglass has no audio. Motion follows your iPhone’s Reduce Motion setting."
          )
          .font(.footnote).foregroundStyle(.secondary)
        }
        Section("Learning") {
          Button("Show the stage guides again") {
            for stage in [Stage.heat, .spin, .shape] {
              UserDefaults.standard.set(false, forKey: "learned.\(stage.rawValue)")
            }
            settingsOpen = false
          }.accessibilityIdentifier("resetTutorialButton")
        }
        Section("Craft") {
          Text("Heat 28% · Balance 28% · Form 44%\n55 Collectible · 75 Exquisite · 90 Masterwork")
            .font(.footnote)
          Text("Progress stays on this device. No account, no network, just glass.")
            .font(.footnote).foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Studio settings")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) { Button("Done") { settingsOpen = false } }
      }
    }
    .tint(Palette.ember)
  }

  private func share(_ piece: GalleryPiece) {
    let renderer = ImageRenderer(content: ResultPrint(piece: piece))
    renderer.scale = 2
    if let image = renderer.uiImage {
      shareImage = image
      shareOpen = true
    }
  }

  private func icon(
    _ symbol: String, label: String, identifier: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 17, weight: .light)).frame(width: 44, height: 44)
    }
    .accessibilityLabel(label).accessibilityIdentifier(identifier)
  }

  private func primary(
    _ title: String, symbol: String, identifier: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 15, weight: .medium))
        Spacer()
        Image(systemName: symbol).font(.system(size: 16))
      }
      .padding(.horizontal, 19).frame(height: 56)
      .background(Palette.ember).foregroundStyle(Palette.background)
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    .buttonStyle(.plain).accessibilityIdentifier(identifier)
  }

  private func eyebrow(_ title: String, color: Color = Palette.muted) -> some View {
    Text(title).font(.system(size: 9, weight: .medium, design: .monospaced))
      .tracking(1.6).foregroundStyle(color)
  }
}

struct ResultPrint: View {
  let piece: GalleryPiece

  var body: some View {
    VStack(spacing: 18) {
      Text("E M B E R G L A S S").font(.system(size: 15, design: .serif))
      Text("MADE OF FIRE. FINISHED BY HAND.")
        .font(.system(size: 8, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
      VesselArt(profile: piece.profile, phase: 1, commission: piece.commission)
        .frame(width: 270, height: 345)
      Plinth().frame(width: 270).padding(.top, -28)
      Text(piece.commission.title).font(.system(size: 33, design: .serif))
      Text("\(piece.grade)  /  \(piece.score)")
        .font(.system(size: 13, design: .monospaced)).tracking(2).foregroundStyle(Palette.mint)
      Text("FIRING \(piece.id.uuidString.prefix(6).uppercased())")
        .font(.system(size: 9, design: .monospaced)).foregroundStyle(Palette.muted)
    }
    .padding(30).frame(width: 390, height: 680)
    .foregroundStyle(Palette.cream).background(Palette.background)
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
