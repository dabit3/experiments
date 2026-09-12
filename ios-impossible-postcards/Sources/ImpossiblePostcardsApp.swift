import SwiftUI

@main
struct ImpossiblePostcardsApp: App {
    var body: some Scene {
        WindowGroup { PostcardsView() }
    }
}

struct PostcardsView: View {
    @StateObject private var game = GameModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var palette: PostcardPalette {
        .chapter(game.journal.chapter)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [PostcardPalette.paper, palette.sky],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
                Group {
                    switch game.page {
                    case .cover: cover(height: geometry.size.height)
                    case .collection: collection
                    case .game: play
                    case .result: result(height: geometry.size.height)
                    }
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                if game.paused {
                    pauseOverlay
                }
                if game.showingHint {
                    hintOverlay
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: game.page)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: game.paused)
            .foregroundStyle(PostcardPalette.ink)
        }
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                game.setPaused(true)
            }
        }
    }

    private func cover(height: Double) -> some View {
        VStack(spacing: 0) {
            HStack {
                eyebrow("A POCKET-SIZED ESCAPE")
                Spacer()
                soundButton
            }
            .padding(.top, 10)
            .padding(.horizontal, 28)
            VStack(spacing: 9) {
                Text("Impossible\nPostcards")
                    .font(.custom("Baskerville", size: height < 700 ? 43 : 49))
                    .lineSpacing(-1)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Small worlds. Wonderful possibilities.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(PostcardPalette.ink.opacity(0.68))
            }
            .padding(.top, height < 700 ? 5 : 22)
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(PostcardPalette.paper.opacity(0.52))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(palette.deep.opacity(0.14), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 15)
                PostcardWorld(chapter: Chapters.all[0], state: Chapters.all[0].initialState)
                    .padding(.horizontal, 27)
                    .padding(.vertical, 13)
                VStack {
                    HStack {
                        Text("01").font(.custom("Baskerville", size: 22))
                        Spacer()
                        Image(systemName: "sun.max").font(.system(size: 20, weight: .ultraLight))
                    }
                    Spacer()
                    HStack {
                        eyebrow("THE QUIET CROSSING")
                        Spacer()
                        Text("35° N · 18° E").font(.system(size: 8, design: .monospaced))
                    }
                }
                .padding(.horizontal, 42)
                .padding(.vertical, 32)
                .allowsHitTesting(false)
            }
            .frame(maxHeight: .infinity)
            HStack(spacing: 23) {
                instructionIcon("hand.tap", title: "Tap to walk")
                instructionIcon("arrow.trianglehead.2.clockwise.rotate.90", title: "Turn to connect")
                instructionIcon("sun.max", title: "Follow the light")
            }
            .padding(.bottom, 24)
            Button { game.start(game.journal.chapter, fresh: !game.canContinue) } label: {
                primaryLabel(game.canContinue ? "Continue your journey" : "Begin your journey", icon: "arrow.right")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 28)
            Button { game.showCollection() } label: {
                Text("The collection  ·  \(game.collected) of 4 postcards")
                    .font(.system(size: 12))
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 7)
        }
    }

    private var play: some View {
        VStack(spacing: 0) {
            HStack {
                roundButton("square.grid.2x2", label: "Open collection") { game.showCollection() }
                Spacer()
                eyebrow("POSTCARD \(roman(game.chapter.id))  /  IV")
                Spacer()
                roundButton("pause", label: "Pause journey") { game.setPaused(true) }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            VStack(spacing: 7) {
                Text(game.chapter.title)
                    .font(.custom("Baskerville", size: 31))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Text(game.chapter.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(PostcardPalette.ink.opacity(0.66))
            }
            .padding(.top, 15)
            .padding(.horizontal, 20)
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%02d", game.state.moves)).font(.custom("Baskerville", size: 28))
                        .contentTransition(.numericText())
                    eyebrow("MOVES")
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0 ..< game.totalSeals, id: \.self) { bit in
                        Image(systemName: game.state.switches & (1 << bit) == 0 ? "sun.max" : "sun.max.fill")
                            .font(.system(size: 17, weight: .light))
                            .foregroundStyle(game.state.switches & (1 << bit) == 0 ? palette.deep
                                .opacity(0.5) : Color(hex: 0xB38A3C))
                    }
                    Text("\(game.seals)/\(game.totalSeals)").font(.system(size: 11, design: .monospaced))
                        .padding(.leading, 3)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(game.seals) of \(game.totalSeals) sun seals lit")
            }
            .padding(.horizontal, 34)
            .padding(.top, 21)
            PostcardWorld(
                chapter: game.chapter, state: game.state, interactive: true,
                rejectedTile: game.rejectedTile, feedbackTick: game.feedbackTick,
                focusedMechanism: game.focusedMechanism, onTile: game.walk
            )
            .id(game.chapter.id)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 8)
            VStack(spacing: 17) {
                Text(game.message)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PostcardPalette.ink.opacity(0.77))
                    .frame(height: 34)
                    .padding(.horizontal, 30)
                    .accessibilityIdentifier("journeyMessage")
                HStack(spacing: 12) {
                    ForEach(game.chapter.mechanisms.indices, id: \.self) { index in
                        turnButton(index)
                    }
                }
                .padding(.horizontal, 28)
                HStack {
                    Button { game.showingHint = true } label: {
                        Label("A little guidance", systemImage: "sparkle")
                            .font(.system(size: 12))
                            .frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    Spacer()
                    if let best = game.journal.best[game.chapter.id] {
                        Text("BEST  \(best)").font(.system(size: 10, weight: .medium, design: .monospaced))
                    } else {
                        Text("Take your time.")
                            .font(.system(size: 11))
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding(.bottom, 4)
        }
    }

    private var collection: some View {
        VStack(spacing: 0) {
            HStack {
                roundButton("arrow.left", label: "Back to title") { game.page = .cover }
                Spacer()
                soundButton
            }.padding(.horizontal, 24).padding(.top, 8)
            VStack(spacing: 9) {
                eyebrow("PLACES THAT STAY WITH YOU")
                Text("The collection").font(.custom("Baskerville", size: 39))
                Text("\(game.collected) of 4 postcards collected")
                    .font(.system(size: 12)).foregroundStyle(PostcardPalette.ink.opacity(0.65))
            }.padding(.top, 14).padding(.bottom, 24)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Chapters.all) { chapter in
                        Button { game.start(chapter.id) } label: {
                            HStack(spacing: 13) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(PostcardPalette.chapter(chapter.id).mist.opacity(0.6))
                                    Image(systemName: ["sun.max", "leaf", "cloud", "moon.stars"][chapter.id])
                                        .font(.system(size: 28, weight: .ultraLight))
                                        .foregroundStyle(PostcardPalette.chapter(chapter.id).deep)
                                    VStack { HStack { Text(roman(chapter.id)).font(.system(
                                        size: 9,
                                        design: .serif
                                    )); Spacer() }; Spacer() }
                                        .padding(9)
                                }.frame(width: 77, height: 90)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(chapter.title).font(.custom("Baskerville", size: 21))
                                    Text(game.journal.best[chapter.id].map { "Collected · best \($0) moves" } ?? chapter
                                        .subtitle)
                                        .font(.system(size: 10)).foregroundStyle(PostcardPalette.ink.opacity(0.65))
                                }
                                Spacer(minLength: 0)
                                Image(systemName: game.journal
                                    .best[chapter.id] == nil ? "arrow.up.right" : "checkmark.seal")
                                    .font(.system(size: 16, weight: .light))
                            }
                            .padding(13)
                            .background(PostcardPalette.paper.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                palette.deep.opacity(0.13),
                                lineWidth: 1
                            ))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            Text("Every journey is saved on this device.")
                .font(.system(size: 10)).foregroundStyle(PostcardPalette.ink.opacity(0.55))
                .padding(.bottom, 18)
        }
    }

    private func result(height: Double) -> some View {
        VStack(spacing: 0) {
            HStack {
                eyebrow("A MOMENT, COLLECTED")
                Spacer()
                Image(systemName: "checkmark.seal").font(.system(size: 23, weight: .ultraLight))
            }.padding(.horizontal, 30).padding(.top, 21)
            VStack(spacing: 8) {
                Text(game.chapter.id == 3 ? "A little closer to home." : "Wish you were here.")
                    .font(.custom("Baskerville", size: height < 700 ? 30 : 34))
                    .minimumScaleFactor(0.8).lineLimit(1)
                Text("POSTCARD \(roman(game.chapter.id))  ·  \(game.chapter.title.uppercased())")
                    .font(.system(size: 10, weight: .medium)).tracking(1.1)
            }.padding(.top, 25).padding(.horizontal, 18)
            PostcardWorld(chapter: game.chapter, state: game.state)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 26)
            Text(game.chapter.letter)
                .font(.custom("Baskerville-Italic", size: 21))
                .lineSpacing(4).multilineTextAlignment(.center)
                .padding(.bottom, 22)
            HStack(spacing: 0) {
                resultMetric("\(game.state.moves)", label: "YOUR MOVES")
                Rectangle().fill(palette.deep.opacity(0.18)).frame(width: 1, height: 33)
                resultMetric("\(game.optimum)", label: "PERFECT ROUTE")
                Rectangle().fill(palette.deep.opacity(0.18)).frame(width: 1, height: 33)
                resultMetric("\(game.journal.best[game.chapter.id] ?? game.state.moves)", label: "LOCAL BEST")
            }.padding(.horizontal, 24)
            Text(game.state.moves == game
                .optimum ? "A perfect little journey." : "Another perspective might take fewer moves.")
                .font(.system(size: 11)).foregroundStyle(palette.deep)
                .padding(.top, 15).padding(.bottom, 25)
            Button {
                if game.chapter.id < 3 {
                    game.start(game.chapter.id + 1)
                } else {
                    game.showCollection()
                }
            } label: {
                primaryLabel(
                    game.chapter.id < 3 ? "The next postcard" : "Return to the collection",
                    icon: "arrow.right"
                )
            }.buttonStyle(InkButtonStyle()).padding(.horizontal, 28)
            HStack(spacing: 28) {
                Button("Try a quieter route") { game.start(game.chapter.id) }
                Button("Collection") { game.showCollection() }
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .frame(minHeight: 50)
            .padding(.bottom, 5)
        }
    }

    private var pauseOverlay: some View {
        overlayCard {
            Image(systemName: "pause.circle").font(.system(size: 35, weight: .ultraLight)).padding(.bottom, 6)
            Text("A quiet moment").font(.custom("Baskerville", size: 31))
            Text("Your place is kept. Stay a while.")
                .font(.system(size: 12)).foregroundStyle(PostcardPalette.ink.opacity(0.65)).padding(.bottom, 20)
            Button { game.setPaused(false) } label: { primaryLabel("Continue walking", icon: "arrow.right") }
                .buttonStyle(InkButtonStyle())
            Button { game.toggleSound() } label: {
                Label(
                    game.journal.sound ? "Sound is on" : "Sound is off",
                    systemImage: game.journal.sound ? "speaker.wave.2" : "speaker.slash"
                )
                .font(.system(size: 13)).frame(minHeight: 44)
            }.buttonStyle(.plain)
            Button("Start this postcard again") { game.start(game.chapter.id) }
                .font(.system(size: 12)).frame(minHeight: 44).buttonStyle(.plain)
            Button("Return to collection") { game.showCollection() }
                .font(.system(size: 12)).frame(minHeight: 44).buttonStyle(.plain)
        }
    }

    private var hintOverlay: some View {
        overlayCard {
            Image(systemName: "sparkle").font(.system(size: 33, weight: .ultraLight)).padding(.bottom, 7)
            Text("A different perspective").font(.custom("Baskerville", size: 28))
            VStack(alignment: .leading, spacing: 18) {
                guidance(
                    "hand.tap",
                    title: "Walk",
                    detail: "Tap a landing. Your traveler takes the connected path, one step at a time."
                )
                guidance(
                    "arrow.clockwise",
                    title: "Turn",
                    detail: "Use the turn buttons to rotate colored bridges. You can ride on their round centers."
                )
                guidance(
                    "sun.max",
                    title: "Awaken",
                    detail: "Step on every sun seal, then walk through the glowing arch."
                )
            }.padding(.vertical, 17)
            Text(game.chapter.hint)
                .font(.custom("Baskerville-Italic", size: 18))
                .multilineTextAlignment(.center).lineSpacing(3)
                .padding(.bottom, 16)
            Text("Each landing crossed and each quarter-turn count as one move. There is no timer.")
                .font(.system(size: 10)).multilineTextAlignment(.center)
                .foregroundStyle(PostcardPalette.ink.opacity(0.6)).padding(.bottom, 16)
            Button { game.showingHint = false } label: { primaryLabel("I see a way", icon: "arrow.right") }
                .buttonStyle(InkButtonStyle())
        }
    }

    private func overlayCard(@ViewBuilder content: () -> some View) -> some View {
        ZStack {
            PostcardPalette.ink.opacity(0.28).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10, content: content)
                    .padding(25)
                    .frame(maxWidth: 360)
                    .background(PostcardPalette.paper, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.8), lineWidth: 1))
                    .padding(22)
            }
            .defaultScrollAnchor(.center)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func turnButton(_ index: Int) -> some View {
        let mechanism = game.chapter.mechanisms[index]
        let enabled = game.chapter.canRotate(index, state: game.state)
        return Button { game.rotate(index) } label: {
            HStack(spacing: 9) {
                if game.chapter.mechanisms.count > 1 {
                    Text(index == 0 ? "I" : "II")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(palette.deep.opacity(0.7), lineWidth: 1))
                } else {
                    Image(systemName: enabled ? "arrow.clockwise" : "lock")
                        .font(.system(size: 21, weight: .light))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(mechanism.name).font(.system(size: 12, weight: .medium))
                    Label(enabled ? "Turn 90°" : "Seal locked", systemImage: enabled ? "arrow.clockwise" : "lock")
                        .font(.system(size: 10, weight: .medium))
                }
                if game.chapter.mechanisms
                    .count == 1
                {
                    Spacer(); Text("↗").font(.system(size: 24, weight: .ultraLight))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.horizontal, 17).padding(.vertical, 13)
            .background(PostcardPalette.paper.opacity(enabled ? 0.88 : 0.42), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(palette.deep.opacity(0.27), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(game.walking)
        .opacity(game.walking ? 0.6 : 1)
        .accessibilityLabel("Turn \(mechanism.name)")
        .accessibilityValue(enabled ? "Quarter turn clockwise" : "Requires first sun seal")
    }

    private var soundButton: some View {
        roundButton(
            game.journal.sound ? "speaker.wave.2" : "speaker.slash",
            label: game.journal.sound ? "Mute sound" : "Enable sound"
        ) {
            game.toggleSound()
        }
    }

    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .light))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.4), in: Circle())
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func primaryLabel(_ text: String, icon: String) -> some View {
        HStack {
            Text(text).font(.system(size: 14, weight: .medium))
            Spacer()
            Image(systemName: icon).font(.system(size: 15, weight: .light))
        }.padding(.horizontal, 21).frame(minHeight: 56)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .medium)).tracking(1.3)
    }

    private func instructionIcon(_ symbol: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 21, weight: .ultraLight)).frame(height: 23)
            Text(title).font(.system(size: 11))
        }
    }

    private func resultMetric(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.custom("Baskerville", size: 30))
            Text(label).font(.system(size: 10, weight: .medium)).tracking(0.5)
        }.frame(maxWidth: .infinity)
    }

    private func guidance(_ symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol).font(.system(size: 21, weight: .light)).frame(width: 29)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.system(size: 12)).lineSpacing(3).foregroundStyle(PostcardPalette.ink.opacity(0.7))
            }
        }
    }

    private func roman(_ index: Int) -> String {
        ["I", "II", "III", "IV"][index]
    }
}

struct InkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(PostcardPalette.paper)
            .background(PostcardPalette.ink, in: RoundedRectangle(cornerRadius: 13))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
