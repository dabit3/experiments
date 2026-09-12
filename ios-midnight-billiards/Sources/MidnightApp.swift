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
                RoomBackdrop(lampX: session.game == nil ? 0.3 : 0.42)
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
                HStack(spacing: 10) {
                    Diamond().fill(Brass.mid).frame(width: 5, height: 8)
                    Text("THE AFTER-HOURS CLUB").font(.system(size: 10, weight: .semibold)).tracking(2.8)
                    Rectangle().fill(Brass.hairline).frame(width: 60, height: 1)
                }
                .foregroundStyle(Brass.mid)
                Text("Midnight\nBilliards")
                    .font(.system(size: 52, weight: .regular, design: .serif))
                    .tracking(-1.5)
                    .lineSpacing(-8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Club.ivory, Club.ivory, Brass.light.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Brass.mid.opacity(0.25), radius: 18, y: 6)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A quiet room. A perfect angle.")
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundStyle(Club.muted)
                HStack(spacing: 18) {
                    stat("\(session.wins)", label: "MATCHES WON")
                    Rectangle().fill(Brass.hairline).frame(width: 1, height: 27)
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
                HStack(alignment: .bottom, spacing: -6) {
                    BallBadge(number: 9, size: 42).offset(y: 3)
                    BallBadge(number: 8, size: 58).zIndex(1)
                    BallBadge(number: 3, size: 42).offset(y: 3)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("TABLE No. 8").font(.system(size: 9, weight: .semibold)).tracking(2)
                            .foregroundStyle(Brass.mid)
                        Text("open from midnight")
                            .font(.system(size: 11, design: .serif).italic())
                            .foregroundStyle(Club.muted)
                    }
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
                HStack(spacing: 8) {
                    Rectangle().fill(Brass.hairline).frame(height: 1)
                    Text("OFFLINE · UNHURRIED · ALWAYS YOUR TABLE")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.3)
                        .foregroundStyle(Club.muted.opacity(0.8))
                        .fixedSize()
                    Rectangle().fill(Brass.hairline).frame(height: 1)
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            BrassText(text: value, size: 23)
            Text(label).font(.system(size: 8, weight: .medium)).tracking(1.2).foregroundStyle(Club.muted)
        }
    }

    private func modeCard(
        title: String, subtitle: String, icon: String, filled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(subtitle).font(.system(size: 8, weight: .semibold)).tracking(1.5)
                        .opacity(0.75)
                    Text(title).font(.system(size: 22, weight: .regular, design: .serif))
                }
                Spacer()
                Image(systemName: icon).font(.system(size: 15, weight: .medium))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().stroke(
                            filled ? Club.ink.opacity(0.35) : Brass.mid.opacity(0.5), lineWidth: 1))
            }
            .foregroundStyle(filled ? Club.ink : Club.ivory)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background {
                if filled {
                    RoundedRectangle(cornerRadius: 14).fill(Brass.gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11).strokeBorder(
                                Club.ink.opacity(0.22), lineWidth: 1
                            )
                            .padding(3)
                        )
                        .shadow(color: Brass.mid.opacity(0.3), radius: 16, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.09, green: 0.16, blue: 0.19), Club.panel.opacity(0.7)],
                                startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14).strokeBorder(
                                LinearGradient(
                                    colors: [Brass.light.opacity(0.55), Brass.deep.opacity(0.25)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
                }
            }
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
                    Image(systemName: "pause").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Brass.light)
                        .frame(width: 44, height: 40)
                        .background(Club.panel.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).strokeBorder(
                                Brass.mid.opacity(0.45), lineWidth: 1))
                }
                .accessibilityLabel("Pause game")
                .accessibilityIdentifier("pauseGame")
                if game.mode == .match {
                    player(
                        name: "YOU", group: game.humanGroup, remaining: game.remaining(for: 0),
                        active: game.turn == 0)
                    BallBadge(number: 8, size: 22)
                    player(
                        name: "AVERY", group: game.group(for: 1), remaining: game.remaining(for: 1),
                        active: game.turn == 1)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        BrassText(text: "\(game.score)", size: 30)
                        Text("POINTS").font(.system(size: 10, weight: .medium)).tracking(1)
                            .foregroundStyle(Club.muted)
                        if game.streak > 1 {
                            Text("×\(min(5, game.streak))").font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Club.ink)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Brass.gradient))
                        }
                    }
                    Spacer()
                    Text("BEST  \(session.best.formatted())").font(.system(size: 11, weight: .medium))
                        .tracking(0.7)
                        .foregroundStyle(Club.muted)
                    let seconds = Int(ceil(game.secondsRemaining))
                    Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                        .foregroundStyle(seconds < 30 ? Color(red: 1, green: 0.57, blue: 0.41) : Brass.light)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Capsule().fill(Club.ink.opacity(0.7)))
                        .overlay(
                            Capsule().strokeBorder(Brass.mid.opacity(seconds < 30 ? 0.9 : 0.45), lineWidth: 1)
                        )
                        .accessibilityIdentifier("challengeTimer")
                }
                Spacer(minLength: 0)
                if game.mode == .challenge {
                    Text("MIDNIGHT").font(.system(size: 9, weight: .medium, design: .serif)).tracking(2.5)
                        .foregroundStyle(Brass.mid.opacity(0.8))
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
                        .font(.system(size: 11.5, design: .serif).italic())
                        .foregroundStyle(Club.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 25)
                }
                controls(game).frame(width: 176)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 3)
    }

    private func player(name: String, group: BallGroup?, remaining: [Int], active: Bool) -> some View {
        HStack(spacing: 7) {
            Diamond().fill(active ? Brass.light : Club.muted.opacity(0.25)).frame(width: 5, height: 8)
                .shadow(color: active ? Brass.mid.opacity(0.9) : .clear, radius: 4)
            VStack(alignment: .leading, spacing: 5) {
                Text(group.map { "\(name) · \($0.rawValue.uppercased())" } ?? name)
                    .font(.system(size: 11, weight: .semibold)).tracking(0.7)
                    .foregroundStyle(active ? Club.ivory : Club.muted)
                if group != nil {
                    HStack(spacing: 3) {
                        if remaining.isEmpty {
                            BallBadge(number: 8, size: 18)
                            Text("CALL POCKET").font(.system(size: 10, weight: .medium)).foregroundStyle(
                                Brass.light)
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
                    .font(.system(size: 9.5, weight: .semibold)).tracking(1.4).foregroundStyle(Brass.mid)
                Spacer()
                Button {
                    session.toggleSound()
                } label: {
                    Image(systemName: session.soundOn ? "speaker.wave.2" : "speaker.slash")
                        .font(.system(size: 12)).foregroundStyle(Brass.light).frame(width: 44, height: 34)
                }
                .accessibilityLabel(session.soundOn ? "Mute sound" : "Enable sound")
            }
            Text(game.status)
                .font(.system(size: 21, weight: .regular, design: .serif))
                .foregroundStyle(Club.ivory)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 46, alignment: .topLeading)
            BrassRule()
            if game.finished {
                Text("Session complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Club.muted)
                Spacer(minLength: 0)
            } else if game.ballInHand && game.turn == 0 {
                Text("BALL IN HAND").font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(
                    Brass.light)
                Text("Tap clear felt to move the cue ball.")
                    .font(.system(size: 12)).foregroundStyle(Club.muted)
                Spacer(minLength: 0)
                actionButton("Place cue ball", icon: "checkmark") { session.confirmPlacement() }
                    .accessibilityIdentifier("confirmPlacement")
            } else {
                HStack {
                    Text("POWER").font(.system(size: 9.5, weight: .medium)).tracking(1.4)
                    Spacer()
                    Text("\(Int(session.power * 100))%").font(
                        .system(size: 12, weight: .medium, design: .monospaced)
                    ).foregroundStyle(Brass.light)
                }.foregroundStyle(Club.muted)
                PowerGauge(power: $session.power, enabled: !(game.shooting || game.turn == 1))
                    .accessibilityIdentifier("shotPower")
                HStack(spacing: 0) {
                    Button {
                        session.angle -= .pi / 720
                    } label: {
                        Image(systemName: "minus").frame(width: 44, height: 44)
                    }.accessibilityLabel("Aim counterclockwise")
                    VStack(spacing: 2) {
                        Text("FINE AIM").font(.system(size: 9, weight: .medium)).tracking(0.8)
                        Text(String(format: "%.2f°", session.angle * 180 / .pi))
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(Brass.light)
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
                .background(Club.ink.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Brass.deep.opacity(0.4), lineWidth: 1)
                )
                .disabled(game.shooting || game.turn == 1)
                HStack(spacing: 10) {
                    Button {
                        session.spin = session.spin == 0 ? 0.75 : session.spin > 0 ? -0.75 : 0
                    } label: {
                        HStack(spacing: 9) {
                            SpinDial(spin: session.spin, size: 32)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("SPIN").font(.system(size: 8, weight: .medium)).tracking(1.2)
                                    .foregroundStyle(Club.muted)
                                Text(session.spin == 0 ? "Center" : session.spin > 0 ? "Follow" : "Draw")
                                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Club.ivory)
                            }
                        }
                        .frame(height: 44)
                    }
                    .accessibilityLabel(
                        "Spin: \(session.spin == 0 ? "center" : session.spin > 0 ? "follow" : "draw"). Tap to change."
                    )
                    .disabled(game.shooting || game.turn == 1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("SHOTS").font(.system(size: 8, weight: .medium)).tracking(1.2)
                            .foregroundStyle(Club.muted)
                        Text("\(game.shots)").font(.system(size: 13, weight: .regular, design: .serif))
                            .monospacedDigit().foregroundStyle(Club.ivory)
                    }
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
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Brass.mid.opacity(0.35)))
                    .accessibilityIdentifier("shotStatus")
                }
            }
        }
        .padding(13)
        .decoFrame(radius: 15, strength: 0.8)
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
            .background(RoundedRectangle(cornerRadius: 9).fill(Brass.gradient))
            .overlay(
                RoundedRectangle(cornerRadius: 7).strokeBorder(Club.ink.opacity(0.22), lineWidth: 1).padding(
                    2)
            )
            .shadow(color: Brass.mid.opacity(0.28), radius: 10, y: 5)
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
                    Text("Your table will be right here.")
                        .font(.system(size: 14, design: .serif).italic()).foregroundStyle(Club.muted)
                }
                VStack(spacing: 10) {
                    actionButton("Back to the table", icon: "play.fill") { session.setPaused(false) }
                    secondaryButton("How to play") { session.showRules = true }
                    BrassRule().padding(.vertical, 2)
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
                        Text(game.resultDetail).font(.system(size: 12.5, design: .serif).italic())
                            .foregroundStyle(Club.muted)
                        if game.mode == .challenge {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                BrassText(text: game.score.formatted(), size: 60)
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
                            game.mode == .challenge
                                ? "BEST  \(session.best.formatted())" : "\(session.wins) MATCHES WON"
                        )
                        .font(.system(size: 10, weight: .medium)).tracking(1.3).foregroundStyle(Brass.mid)
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
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(number).font(.system(size: 11, weight: .regular, design: .serif)).foregroundStyle(
                    Brass.mid)
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Club.ivory)
            }
            Text(text).font(.system(size: 11)).foregroundStyle(Club.muted).fixedSize(
                horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eyebrow(_ title: String) -> some View {
        HStack(spacing: 8) {
            Diamond().fill(Brass.mid).frame(width: 4, height: 7)
            Text(title).font(.system(size: 9, weight: .medium)).tracking(1.8).foregroundStyle(Brass.mid)
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(Club.ivory)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(Club.ivory.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Brass.mid.opacity(0.28), lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Club.ink.opacity(0.5).ignoresSafeArea()
            content()
                .padding(28)
                .frame(maxWidth: 660)
                .decoFrame(radius: 20)
                .padding(14)
        }
    }
}
