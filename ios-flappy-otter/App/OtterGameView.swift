import SwiftUI

struct OtterGameView: View {
  @State private var store = GameStore()
  @State private var showGuide = false
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    ZStack {
      RiverScene(game: store.game, home: store.home)
      if store.home {
        home
      } else {
        flight
      }
    }
    .fontDesign(.rounded)
    .foregroundStyle(RiverPalette.ink)
    .onAppear { store.startClock() }
    .onDisappear { store.stopClock() }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { store.pause() }
    }
    .sheet(isPresented: $showGuide) { guide }
  }

  private var home: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          HStack {
            HStack(spacing: 7) {
              Image(systemName: "water.waves")
                .font(.system(size: 17, weight: .bold))
              Text("LITTLE RIVER CLUB")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
            }
            Spacer()
            soundButton
          }
          .padding(.top, 10)

          VStack(spacing: -7) {
            Text("flappy")
              .font(.system(size: 64, weight: .black, design: .rounded))
              .tracking(-3)
            Text("otter")
              .font(.system(size: 88, weight: .black, design: .rounded))
              .tracking(-5)
              .foregroundStyle(RiverPalette.orange)
              .shadow(color: Color(red: 0.71, green: 0.35, blue: 0.18), radius: 0, y: 4)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Flappy Otter")
          .padding(.top, 20)
          Text("Small paws. Big adventure.")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(RiverPalette.muted)
            .padding(.top, 13)

          hero
            .frame(height: max(168, min(235, geometry.size.height * 0.30)))
            .padding(.top, 4)

          HStack(spacing: 0) {
            stat(value: "\(store.record.best)", label: "PERSONAL BEST", symbol: "trophy.fill")
            Rectangle().fill(RiverPalette.ink.opacity(0.12)).frame(width: 1, height: 33)
            stat(
              value: "\(store.record.flights)", label: "RIVER FLIGHTS", symbol: "paperplane.fill")
          }
          .padding(.vertical, 16)
          .background(RiverPalette.cream.opacity(0.85), in: RoundedRectangle(cornerRadius: 22))
          .overlay(
            RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.65), lineWidth: 1)
          )
          .padding(.horizontal, 8)
          .padding(.bottom, 20)

          action("Let's fly", symbol: "arrow.right", accessibility: "Start flight") {
            store.prepareFlight()
          }
          .accessibilityIdentifier("start-flight")
          Button {
            showGuide = true
          } label: {
            Label("How to fly", systemImage: "hand.tap")
              .font(.system(size: 14, weight: .bold))
              .frame(minHeight: 48)
              .frame(maxWidth: .infinity)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .padding(.top, 8)
          Spacer(minLength: 12)
          Text("ONE MORE TAP. ONE MORE ADVENTURE.")
            .font(.system(size: 8, weight: .heavy))
            .tracking(1.8)
            .foregroundStyle(RiverPalette.cream.opacity(0.85))
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
        .frame(minHeight: geometry.size.height)
      }
      .scrollIndicators(.hidden)
    }
  }

  private var hero: some View {
    ZStack {
      Ellipse()
        .fill(RiverPalette.ink.opacity(0.12))
        .frame(width: 150, height: 17)
        .offset(x: 8, y: 88)
      Circle()
        .strokeBorder(.white.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 8]))
        .frame(width: 201, height: 201)
      Image(systemName: "sparkle")
        .font(.system(size: 27, weight: .medium))
        .foregroundStyle(RiverPalette.gold)
        .offset(x: 118, y: -42)
      Image(systemName: "sparkle")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(RiverPalette.teal)
        .offset(x: -115, y: 24)
      Image("Otter")
        .resizable()
        .scaledToFit()
        .frame(width: 207, height: 195)
        .rotationEffect(.degrees(-9))
        .shadow(color: RiverPalette.ink.opacity(0.12), radius: 0, x: 2, y: 7)
      Text("meet Wiskers!")
        .font(.system(size: 11, weight: .bold))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RiverPalette.cream, in: Capsule())
        .rotationEffect(.degrees(-8))
        .offset(x: -85, y: -75)
    }
    .accessibilityLabel("Wiskers, a cute orange otter holding a laptop")
  }

  private var flight: some View {
    ZStack {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { store.flap() }
        .accessibilityLabel("Flap")
        .accessibilityHint("Double tap repeatedly to stay between the river rocks")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { store.flap() }
        .accessibilityIdentifier("flap")
        .ignoresSafeArea()

      VStack {
        HStack(alignment: .top) {
          HStack(spacing: 5) {
            Image(systemName: "trophy.fill").foregroundStyle(RiverPalette.gold)
            Text("BEST \(store.record.best)")
              .tracking(1)
          }
          .font(.system(size: 11, weight: .heavy))
          .padding(.horizontal, 13)
          .padding(.vertical, 11)
          .background(RiverPalette.cream.opacity(0.9), in: Capsule())
          Spacer()
          circleButton("Pause flight", symbol: "pause.fill") { store.pause() }
            .disabled(store.game.phase != .playing)
            .opacity(store.game.phase == .playing ? 1 : 0.4)
        }
        .overlay(alignment: .top) {
          VStack(spacing: -3) {
            Text("\(store.game.score)")
              .font(.system(size: 57, weight: .black))
              .contentTransition(.numericText())
            Text("GATES")
              .font(.system(size: 9, weight: .heavy))
              .tracking(2.5)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Score \(store.game.score)")
        }
        Spacer()
        if store.game.phase == .playing && store.game.elapsed < 3 {
          Label("Nice and easy. Tap to stay up.", systemImage: "hand.tap")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(RiverPalette.cream)
            .padding(.bottom, 20)
            .allowsHitTesting(false)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .allowsHitTesting(store.game.phase == .playing)

      switch store.game.phase {
      case .ready:
        VStack(spacing: 14) {
          Text("Ready, little otter?")
            .font(.system(size: 27, weight: .black))
          Text("Tap anywhere to flap.\nFind your way through the gaps.")
            .font(.system(size: 15, weight: .medium))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
          Image(systemName: "hand.tap.fill")
            .font(.system(size: 36))
            .padding(.top, 8)
          Text("TAP TO BEGIN")
            .font(.system(size: 10, weight: .heavy))
            .tracking(2.5)
        }
        .padding(28)
        .background(RiverPalette.cream.opacity(0.95), in: RoundedRectangle(cornerRadius: 28))
        .offset(y: 85)
        .allowsHitTesting(false)
        VStack {
          HStack {
            circleButton("Back to river", symbol: "arrow.left") { store.goHome() }
            Spacer()
          }
          Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 62)
      case .paused:
        paused
      case .finished:
        results
      case .playing:
        EmptyView()
      }
    }
  }

  private var paused: some View {
    modal {
      Image(systemName: "cup.and.saucer.fill")
        .font(.system(size: 38))
        .foregroundStyle(RiverPalette.teal)
      Text("A little breather.")
        .font(.system(size: 28, weight: .black))
      Text("Your river adventure can wait.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(RiverPalette.muted)
      action("Keep flying", symbol: "play.fill") { store.resume() }
        .padding(.top, 10)
      HStack(spacing: 16) {
        soundButton
        circleButton(
          store.record.haptics ? "Turn haptics off" : "Turn haptics on",
          symbol: store.record.haptics ? "hand.tap.fill" : "hand.tap"
        ) { store.toggleHaptics() }
      }
      Button("Back to the river") { store.goHome() }
        .font(.system(size: 14, weight: .bold))
        .frame(minHeight: 44)
    }
  }

  private var results: some View {
    modal {
      HStack(spacing: 7) {
        Image(systemName: store.newBest ? "sparkles" : "water.waves")
        Text(store.newBest ? "A NEW PERSONAL BEST!" : "A LITTLE SPLASH")
          .tracking(1.5)
      }
      .font(.system(size: 10, weight: .heavy))
      .foregroundStyle(RiverPalette.muted)
      Text(store.newBest ? "Otterly amazing." : "Otterly close!")
        .font(.system(size: 30, weight: .black))
        .minimumScaleFactor(0.75)
        .lineLimit(1)
      Image("Otter")
        .resizable()
        .scaledToFit()
        .frame(height: 88)
        .rotationEffect(.degrees(-7))
      HStack {
        VStack(spacing: 0) {
          Text("\(store.game.score)").font(.system(size: 55, weight: .black))
          Text("THIS FLIGHT").font(.system(size: 9, weight: .heavy)).tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        Rectangle().fill(RiverPalette.ink.opacity(0.12)).frame(width: 1, height: 52)
        VStack(spacing: 0) {
          Text("\(store.record.best)").font(.system(size: 55, weight: .black))
          Text("PERSONAL BEST").font(.system(size: 9, weight: .heavy)).tracking(1.5)
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.bottom, 8)
      Label(FlightMedal(score: store.game.score).rawValue, systemImage: "rosette")
        .font(.system(size: 14, weight: .bold))
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(RiverPalette.gold.opacity(0.27), in: Capsule())
      if let target = FlightMedal(score: store.game.score).nextTarget {
        Text("\(target) gates to your next river badge.")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(RiverPalette.muted)
      }
      action("One more flight", symbol: "arrow.clockwise") { store.prepareFlight() }
        .padding(.top, 7)
        .accessibilityIdentifier("retry-flight")
      HStack(spacing: 24) {
        Button("Home") { store.goHome() }
        ShareLink(
          item:
            "I flew through \(store.game.score) gates in Flappy Otter! My personal best is \(store.record.best). Can you beat Wiskers?"
        ) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
      .font(.system(size: 14, weight: .bold))
      .frame(minHeight: 44)
    }
  }

  private var guide: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 25) {
          Image("Otter").resizable().scaledToFit().frame(height: 130).frame(maxWidth: .infinity)
          Text("A tiny guide to\nbig adventures.")
            .font(.system(size: 34, weight: .black, design: .rounded))
          guideRow(
            "01", title: "Tap. Flap. Repeat.",
            text: "Each tap gives Wiskers a little lift. Stop tapping and gravity takes over.")
          guideRow(
            "02", title: "Mind the gap.",
            text:
              "Fly between the mossy river rocks. Clear a pair to earn one point. The sky and water are off limits!"
          )
          guideRow(
            "03", title: "Make a little progress.",
            text:
              "Find your rhythm and chase your best. Earn river badges at 5, 15, 30 and 50 gates.")
          HStack {
            Text("Sound effects")
            Spacer()
            Toggle(
              "Sound effects",
              isOn: Binding(
                get: { store.record.sound }, set: { _ in store.toggleSound() }
              )
            ).labelsHidden()
          }
          HStack {
            Text("Haptics")
            Spacer()
            Toggle(
              "Haptics",
              isOn: Binding(
                get: { store.record.haptics }, set: { _ in store.toggleHaptics() }
              )
            ).labelsHidden()
          }
          Text("Play at your own pace. Pause any time. Your best stays on this iPhone.")
            .font(.footnote)
            .foregroundStyle(RiverPalette.muted)
        }
        .padding(28)
      }
      .background(RiverPalette.cream)
      .foregroundStyle(RiverPalette.ink)
      .tint(RiverPalette.teal)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Got it") { showGuide = false }
        }
      }
    }
    .presentationDragIndicator(.visible)
  }

  private var soundButton: some View {
    circleButton(
      store.record.sound ? "Turn sound off" : "Turn sound on",
      symbol: store.record.sound ? "speaker.wave.2" : "speaker.slash"
    ) { store.toggleSound() }
  }

  private func circleButton(_ title: String, symbol: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 17, weight: .bold))
        .frame(width: 46, height: 46)
        .background(RiverPalette.cream.opacity(0.8), in: Circle())
        .overlay(Circle().strokeBorder(RiverPalette.ink.opacity(0.10), lineWidth: 1))
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }

  private func stat(value: String, label: String, symbol: String) -> some View {
    VStack(spacing: 6) {
      HStack(spacing: 7) {
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(RiverPalette.orange)
        Text(value).font(.system(size: 25, weight: .black))
      }
      Text(label).font(.system(size: 8, weight: .heavy)).tracking(1.3)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  private func action(
    _ title: String, symbol: String, accessibility: String? = nil, perform: @escaping () -> Void
  ) -> some View {
    Button(action: perform) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 20, weight: .heavy))
        Spacer()
        Image(systemName: symbol).font(.system(size: 18, weight: .bold))
      }
      .padding(.horizontal, 25)
      .frame(minHeight: 63)
      .background(RiverPalette.orange, in: RoundedRectangle(cornerRadius: 22))
      .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.22), lineWidth: 1))
      .shadow(color: Color(red: 0.68, green: 0.31, blue: 0.17), radius: 0, y: 5)
      .contentShape(RoundedRectangle(cornerRadius: 22))
    }
    .buttonStyle(FlightButtonStyle())
    .accessibilityLabel(accessibility ?? title)
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      RiverPalette.ink.opacity(0.35).ignoresSafeArea()
      ScrollView {
        VStack(spacing: 16, content: content)
          .padding(26)
          .frame(maxWidth: 360)
          .background(RiverPalette.cream, in: RoundedRectangle(cornerRadius: 32))
          .padding(24)
          .frame(maxWidth: .infinity)
      }
      .scrollBounceBehavior(.basedOnSize)
      .defaultScrollAnchor(.center)
    }
  }

  private func guideRow(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 17) {
      Text(number).font(.system(size: 15, weight: .black)).foregroundStyle(RiverPalette.orange)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 19, weight: .heavy))
        Text(text).font(.system(size: 15)).foregroundStyle(RiverPalette.muted).lineSpacing(3)
      }
    }
  }
}

private struct FlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .offset(y: configuration.isPressed ? 3 : 0)
  }
}
