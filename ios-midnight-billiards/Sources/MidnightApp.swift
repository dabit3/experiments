import SwiftUI

@main
struct MidnightApp: App {
    @StateObject private var session = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ClubView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
                .onReceive(session.timer) { session.tick($0) }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active && session.game != nil { session.setPaused(true) }
                }
        }
    }
}

struct ClubView: View {
    @EnvironmentObject private var session: GameSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Club.ink.ignoresSafeArea()
                RadialGradient(
                    colors: [Club.teal.opacity(0.065), .clear],
                    center: .topTrailing, startRadius: 0, endRadius: geometry.size.width
                ).ignoresSafeArea()
                if let game = session.game {
                    playView(game)
                } else {
                    home
                }
                if session.paused && session.game?.finished == false {
                    pauseOverlay
                }
                if session.game?.finished == true {
                    results
                }
                if session.showRules {
                    rules
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: session.paused)
        }
        .tint(Club.gold)
        .statusBarHidden()
    }

    private var home: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill").font(.system(size: 12))
                    Text("THE AFTER-HOURS CLUB").font(.system(size: 10, weight: .semibold)).tracking(2.5)
                }
                .foregroundStyle(Club.gold)
                Text("Midnight\nBilliards")
                    .font(.system(size: 49, weight: .regular, design: .serif))
                    .tracking(-1.5)
                    .lineSpacing(-7)
                    .foregroundStyle(Club.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A quiet room. A perfect angle.")
                    .font(.system(size: 13))
                    .foregroundStyle(Club.muted)
                HStack(spacing: 18) {
                    stat("\(session.wins)", label: "MATCHES WON")
                    Rectangle().fill(Club.gold.opacity(0.2)).frame(width: 1, height: 27)
                    stat(session.best.formatted(), label: "PERSONAL BEST")
                }
                .padding(.top, 8)
                HStack(spacing: 15) {
                    Button {
                        session.showRules = true
                    } label: {
                        Label("How to play", systemImage: "questionmark.circle")
                    }
                    Button {
                        session.toggleSound()
                    } label: {
                        Image(systemName: session.soundOn ? "speaker.wave.2" : "speaker.slash")
                    }
                    .accessibilityLabel(session.soundOn ? "Mute sound" : "Enable sound")
                }
                .font(.system(size: 12))
                .foregroundStyle(Club.muted)
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                HStack(spacing: -4) {
                    BallBadge(number: 9, size: 44).offset(y: 6)
                    BallBadge(number: 8, size: 59).zIndex(1)
                    BallBadge(number: 3, size: 44).offset(y: 6)
                    Spacer()
                    Text("EST.\n00:00")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .tracking(2)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Club.gold.opacity(0.75))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                modeCard(
                    title: "The house table", subtitle: "8-BALL  /  YOU VS AVERY",
                    icon: "arrow.up.right", filled: true
                ) { session.start(.match) }
                modeCard(
                    title: "Against the clock", subtitle: "3 MINUTES  /  SOLO POTTING",
                    icon: "timer", filled: false
                ) { session.start(.challenge) }
                Text("OFFLINE. UNHURRIED. ALWAYS YOUR TABLE.")
                    .font(.system(size: 8, weight: .medium))
                    .tracking(1.3)
                    .foregroundStyle(Club.muted.opacity(0.7))
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(size: 23, weight: .regular, design: .serif)).foregroundStyle(Club.ivory)
            Text(label).font(.system(size: 8, weight: .medium)).tracking(1.2).foregroundStyle(Club.muted)
        }
    }

    private func modeCard(
        title: String, subtitle: String, icon: String, filled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text(subtitle).font(.system(size: 8, weight: .semibold)).tracking(1.5)
                        .opacity(0.7)
                    Text(title).font(.system(size: 22, weight: .regular, design: .serif))
                }
                Spacer()
                Image(systemName: icon).font(.system(size: 18, weight: .light))
            }
            .foregroundStyle(filled ? Club.ink : Club.ivory)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(filled ? Club.gold : Club.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Club.gold.opacity(filled ? 0 : 0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(filled ? "startMatch" : "startChallenge")
    }

    private func playView(_ game: GameEngine) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Button {
                    session.setPaused(true)
                } label: {
                    Image(systemName: "pause").font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 40)
                        .background(Club.panel, in: RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("Pause game")
                .accessibilityIdentifier("pauseGame")
                if game.mode == .match {
                    player(
                        name: "YOU", group: game.humanGroup, remaining: game.remaining(for: 0),
                        active: game.turn == 0)
                    Text("8").font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(Club.gold)
                    player(
                        name: "AVERY", group: game.group(for: 1), remaining: game.remaining(for: 1),
                        active: game.turn == 1)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(game.score)").font(.system(size: 29, weight: .regular, design: .serif))
                            .monospacedDigit()
                        Text("POINTS").font(.system(size: 10, weight: .medium)).tracking(0.8)
                            .foregroundStyle(Club.muted)
                        if game.streak > 1 {
                            Text("×\(min(5, game.streak))").font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Club.gold)
                        }
                    }
                    Spacer()
                    Text("BEST  \(session.best)").font(.system(size: 11, weight: .medium)).tracking(0.7)
                        .foregroundStyle(Club.muted)
                    let seconds = Int(ceil(game.secondsRemaining))
                    Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                        .font(.system(size: 25, weight: .light, design: .monospaced))
                        .foregroundStyle(seconds < 30 ? Color(red: 1, green: 0.57, blue: 0.41) : Club.gold)
                        .accessibilityIdentifier("challengeTimer")
                }
                Spacer(minLength: 0)
                if game.mode == .challenge {
                    Text("MIDNIGHT").font(.system(size: 9, weight: .medium, design: .serif)).tracking(2)
                        .foregroundStyle(Club.gold.opacity(0.7))
                }
            }
            .foregroundStyle(Club.ivory)
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    TableView(
                        table: game.table, angle: session.angle, power: session.power,
                        aiming: !game.shooting && !game.ballInHand && !game.finished,
                        ballInHand: game.ballInHand, kitchen: game.kitchen,
                        calledPocket: game.calledPocket, requireCall: game.requiresCall,
                        onTouch: session.touchTable)
                    Spacer(minLength: 0)
                    Text(game.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Club.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 25)
                }
                controls(game).frame(width: 174)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 3)
    }

    private func player(name: String, group: BallGroup?, remaining: [Int], active: Bool) -> some View {
        HStack(spacing: 7) {
            Circle().fill(active ? Club.teal : Club.muted.opacity(0.25)).frame(width: 5, height: 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(group.map { "\(name) · \($0.rawValue.uppercased())" } ?? name)
                    .font(.system(size: 11, weight: .semibold)).tracking(0.7)
                    .foregroundStyle(active ? Club.ivory : Club.muted)
                if group != nil {
                    HStack(spacing: 3) {
                        if remaining.isEmpty {
                            BallBadge(number: 8, size: 18)
                            Text("CALL POCKET").font(.system(size: 10, weight: .medium)).foregroundStyle(
                                Club.gold)
                        } else {
                            ForEach(remaining, id: \.self) { BallBadge(number: $0, size: 18) }
                        }
                    }
                } else {
                    Text("OPEN TABLE").font(.system(size: 10, weight: .medium)).tracking(0.7).foregroundStyle(
                        Club.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func controls(_ game: GameEngine) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(game.mode == .match ? "HOUSE TABLE" : "SOLO SESSION")
                    .font(.system(size: 10, weight: .semibold)).tracking(0.8).foregroundStyle(Club.gold)
                Spacer()
                Button {
                    session.toggleSound()
                } label: {
                    Image(systemName: session.soundOn ? "speaker.wave.2" : "speaker.slash")
                        .font(.system(size: 13)).frame(width: 44, height: 34)
                }
                .accessibilityLabel(session.soundOn ? "Mute sound" : "Enable sound")
            }
            Text(game.status)
                .font(.system(size: 21, weight: .regular, design: .serif))
                .foregroundStyle(Club.ivory)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 46, alignment: .topLeading)
            Rectangle().fill(Club.gold.opacity(0.18)).frame(height: 1)
            if game.finished {
                Text("Session complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Club.muted)
                Spacer(minLength: 0)
            } else if game.ballInHand && game.turn == 0 {
                Text("BALL IN HAND").font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(
                    Club.gold)
                Text("Tap clear felt to move the cue ball.")
                    .font(.system(size: 12)).foregroundStyle(Club.muted)
                Spacer(minLength: 0)
                actionButton("Place cue ball", icon: "checkmark") { session.confirmPlacement() }
                    .accessibilityIdentifier("confirmPlacement")
            } else {
                HStack {
                    Text("POWER").font(.system(size: 10, weight: .medium)).tracking(1)
                    Spacer()
                    Text("\(Int(session.power * 100))%").font(
                        .system(size: 12, weight: .medium, design: .monospaced))
                }.foregroundStyle(Club.muted)
                Slider(value: $session.power, in: 0.05...1)
                    .accessibilityLabel("Shot power")
                    .accessibilityIdentifier("shotPower")
                    .frame(height: 21)
                    .disabled(game.shooting || game.turn == 1)
                HStack(spacing: 0) {
                    Button {
                        session.angle -= .pi / 720
                    } label: {
                        Image(systemName: "minus").frame(width: 44, height: 44)
                    }.accessibilityLabel("Aim counterclockwise")
                    VStack(spacing: 2) {
                        Text("FINE AIM").font(.system(size: 9, weight: .medium)).tracking(0.5)
                        Text(String(format: "%.2f°", session.angle * 180 / .pi))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Club.gold)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("aimAngle")
                    Button {
                        session.angle += .pi / 720
                    } label: {
                        Image(systemName: "plus").frame(width: 44, height: 44)
                    }.accessibilityLabel("Aim clockwise")
                }
                .font(.system(size: 12))
                .foregroundStyle(Club.ivory)
                .background(Club.ink.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .disabled(game.shooting || game.turn == 1)
                HStack {
                    Button {
                        session.spin = session.spin == 0 ? 0.75 : session.spin > 0 ? -0.75 : 0
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle().fill(Club.ivory).frame(width: 18, height: 18)
                                Circle().fill(Club.gold).frame(width: 5, height: 5).offset(
                                    y: -session.spin * 6)
                            }
                            Text(session.spin == 0 ? "CENTER" : session.spin > 0 ? "FOLLOW" : "DRAW")
                                .font(.system(size: 10, weight: .medium)).tracking(0.6)
                        }
                        .frame(height: 30)
                    }
                    .accessibilityLabel(
                        "Spin: \(session.spin == 0 ? "center" : session.spin > 0 ? "follow" : "draw"). Tap to change."
                    )
                    .disabled(game.shooting || game.turn == 1)
                    Spacer()
                    Text("\(game.shots) SHOTS").font(.system(size: 10)).foregroundStyle(Club.muted)
                }
                Spacer(minLength: 0)
                if game.canShoot && game.turn == 0 {
                    actionButton("Take shot", icon: "arrow.right") { session.strike() }
                        .accessibilityIdentifier("takeShot")
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: game.shooting ? "circle.dotted" : "scope")
                        Text(
                            game.shooting
                                ? "Balls rolling" : game.turn == 1 ? "Avery’s turn" : "Call a pocket"
                        )
                        .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Club.ivory)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Club.ink.opacity(0.6), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Club.gold.opacity(0.3)))
                    .accessibilityIdentifier("shotStatus")
                }
            }
        }
        .padding(13)
        .background(Club.panel, in: RoundedRectangle(cornerRadius: 15))
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 5)
                Image(systemName: icon).font(.system(size: 13))
            }
            .foregroundStyle(Club.ink)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Club.gold, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var pauseOverlay: some View {
        modal {
            HStack(spacing: 36) {
                VStack(alignment: .leading, spacing: 12) {
                    eyebrow("A MOMENT BETWEEN SHOTS")
                    Text("Take your time.").font(.system(size: 37, weight: .regular, design: .serif))
                        .foregroundStyle(Club.ivory)
                    Text("Your table will be right here.").font(.system(size: 13)).foregroundStyle(Club.muted)
                }
                VStack(spacing: 10) {
                    actionButton("Back to the table", icon: "play.fill") { session.setPaused(false) }
                    secondaryButton("How to play") { session.showRules = true }
                    Rectangle().fill(Club.gold.opacity(0.2)).frame(height: 1)
                    secondaryButton("Start a fresh rack") {
                        if let mode = session.game?.mode { session.start(mode) }
                    }
                    secondaryButton("Leave the room") {
                        session.game = nil; session.paused = false
                    }
                }.frame(width: 195)
            }
        }
    }

    private var results: some View {
        modal {
            if let game = session.game {
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        eyebrow(
                            game.mode == .challenge
                                ? (session.newBest ? "A NEW PERSONAL BEST" : "SESSION COMPLETE")
                                : "THE LAST BALL")
                        Text(game.resultTitle)
                            .font(.system(size: 35, weight: .regular, design: .serif))
                            .foregroundStyle(Club.ivory)
                        Text(game.resultDetail).font(.system(size: 12)).foregroundStyle(Club.muted)
                        if game.mode == .challenge {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(game.score)").font(
                                    .system(size: 59, weight: .regular, design: .serif)
                                ).foregroundStyle(Club.gold)
                                Text("POINTS").font(.system(size: 10, weight: .medium)).tracking(2)
                                    .foregroundStyle(Club.muted)
                            }
                        } else {
                            BallBadge(number: 8, size: 57).padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 12) {
                        Text(
                            game.mode == .challenge ? "BEST  \(session.best)" : "\(session.wins) MATCHES WON"
                        )
                        .font(.system(size: 10, weight: .medium)).tracking(1.3).foregroundStyle(Club.gold)
                        actionButton("Play again", icon: "arrow.clockwise") { session.start(game.mode) }
                        secondaryButton("Back to the club") { session.game = nil }
                    }.frame(width: 185)
                }
            }
        }
    }

    private var rules: some View {
        modal {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        eyebrow("A FEW HOUSE RULES")
                        Text("Make yourself at home.").font(
                            .system(size: 29, weight: .regular, design: .serif)
                        ).foregroundStyle(Club.ivory)
                    }
                    Spacer()
                    Button {
                        session.showRules = false
                    } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }.accessibilityLabel("Close rules")
                }
                ScrollView {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 13) {
                            rule(
                                "01", "Find the line",
                                "Tap or drag on the felt to aim. The white line predicts cue contact; gold shows the object-ball or bank direction. Fine aim adjusts ¼°."
                            )
                            rule(
                                "02", "Feel the shot",
                                "Set power, then Take shot. Tap the cue-ball control for center, follow or draw. Aim resets toward a suggested angle after each shot; refine it before shooting."
                            )
                            rule(
                                "03", "Beat the clock",
                                "Three minutes. Each ball earns 100 × your consecutive potting-shot streak, up to 5×. A miss resets it. Scratch: −50 and ball in hand. Clear a rack: +500. The last shot settles after time."
                            )
                        }
                        VStack(alignment: .leading, spacing: 13) {
                            rule(
                                "04", "Own your group",
                                "The table stays open after the break. The first group potted on a legal later shot becomes yours. If both fall, the first ball decides. Pot your group to keep the turn."
                            )
                            rule(
                                "05", "Keep it clean",
                                "Hit your group first (not the eight on an open table); then a ball must reach a rail or pocket. A scratch or foul gives the other player ball in hand. The break needs a pot or four object balls to rails; break fouls place behind the head string."
                            )
                            rule(
                                "06", "Call the eight",
                                "Clear your seven, tap a pocket to call it, then pot the eight there. An early eight, wrong pocket or scratch on the eight loses. An eight on the break is respotted. House rules: only the eight needs a called pocket."
                            )
                        }
                    }
                }
                .frame(maxHeight: 210)
            }
        }
    }

    private func rule(_ number: String, _ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(number)  \(title)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Club.gold)
            Text(text).font(.system(size: 11)).foregroundStyle(Club.muted).fixedSize(
                horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eyebrow(_ title: String) -> some View {
        Text(title).font(.system(size: 9, weight: .medium)).tracking(1.8).foregroundStyle(Club.gold)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(Club.ivory)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(Club.ivory.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Club.ink.opacity(0.89).ignoresSafeArea()
            content()
                .padding(26)
                .frame(maxWidth: 660)
                .background(Club.panel, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Club.gold.opacity(0.25), lineWidth: 1))
                .padding(14)
        }
    }
}
