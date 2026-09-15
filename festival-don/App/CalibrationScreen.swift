import SwiftUI

struct CalibrationScreen: View {
    @ObservedObject var game: GameClient
    var body: some View {
        ZStack {
            FestivalPalette.ink.opacity(0.75)
            FestivalPanel {
                HStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("Find your rhythm").font(.system(size: 30, weight: .black))
                        Text("Red faces → drum center\nBlue faces → blue rim\nBig faces → both drums together\nYellow bars → roll either color")
                            .font(.system(size: 15, weight: .bold)).lineSpacing(6)
                        HStack {
                            Text("GOOD  ±45ms").foregroundStyle(FestivalPalette.coral)
                            Text("OK  ±100ms").foregroundStyle(FestivalPalette.blue)
                        }.font(.system(size: 11, weight: .black))
                        Text("Use wired audio or the speakers.\nBluetooth latency varies by device.")
                            .font(.system(size: 11, weight: .medium)).lineSpacing(3)
                    }.frame(width: 320)
                    VStack(spacing: 12) {
                        Text("TIMING OFFSET").font(.system(size: 11, weight: .black)).tracking(2)
                        Text("\(Int(game.calibration)) ms").font(.system(size: 36, weight: .black, design: .rounded)).monospacedDigit()
                        Slider(value: $game.calibration, in: -120...120, step: 1) { editing in
                            if !editing { game.saveCalibration() }
                        }.tint(FestivalPalette.coral).accessibilityIdentifier("timing-offset")
                        Text("Positive values compensate late taps.").font(.system(size: 10, weight: .semibold))
                        Button(game.calibrationRunning ? "TAP WITH THE CLICK  \(game.calibrationTaps.count)/8" : "Start 8-tap calibration") {
                            if game.calibrationRunning { game.calibrationTap() } else { game.beginCalibration() }
                        }.buttonStyle(FestivalButton()).accessibilityIdentifier("calibration-tap")
                        HStack {
                            Button("Reset") { game.calibration = 0; game.saveCalibration() }
                            Spacer()
                            Button("Done") {
                                game.calibrationRunning = false
                                game.saveCalibration()
                                game.showCalibration = false
                            }.fontWeight(.black).accessibilityIdentifier("calibration-done")
                        }.font(.system(size: 13, weight: .bold)).padding(.top, 8)
                    }.frame(width: 284)
                }.padding(8)
            }.frame(width: 734)
        }
    }
}
