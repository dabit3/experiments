import SwiftUI

struct MixerView: View {
  @EnvironmentObject private var store: HushStore
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var sheet: HushSheet?
  @State private var showReset = false

  var body: some View {
    ZStack {
      HushStyle.ink.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 0) {
          header
          hero
          mixer
        }
        .padding(.bottom, 16)
      }
      .scrollIndicators(.hidden)
    }
    .foregroundStyle(HushStyle.silver)
    .safeAreaInset(edge: .bottom, spacing: 0) { playbackDock }
    .sheet(item: $sheet) { item in
      switch item {
      case .scenes: SceneLibrary()
      case .save: SaveSceneView()
      case .timer: TimerView()
      case .settings: SettingsView()
      }
    }
    .alert(
      "Audio unavailable",
      isPresented: Binding(
        get: { store.error != nil }, set: { if !$0 { store.error = nil } })
    ) {
      Button("OK") { store.error = nil }
    } message: {
      Text(store.error ?? "")
    }
    .confirmationDialog(
      "Clear all four sound layers?", isPresented: $showReset, titleVisibility: .visible
    ) {
      Button("Clear mix", role: .destructive) { store.resetMix() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your saved scenes will stay in your library.")
    }
  }

  private var header: some View {
    HStack(alignment: .center) {
      HStack(spacing: 6) {
        Image(systemName: "moonphase.waning.crescent")
          .font(.system(size: 17, weight: .light))
          .foregroundStyle(HushStyle.lavender)
        Text("hush").font(.system(size: 32, weight: .regular, design: .serif)).tracking(-1.5)
      }
      .accessibilityElement(children: .combine)
      Spacer()
      Button {
        sheet = .scenes
      } label: {
        Label("Scenes", systemImage: "square.stack.3d.up")
          .font(.subheadline.weight(.medium))
          .padding(.horizontal, 16).frame(minHeight: 44)
          .background(.white.opacity(0.055), in: Capsule())
          .overlay(Capsule().stroke(.white.opacity(0.08)))
      }
      Button {
        sheet = .settings
      } label: {
        Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
      }.accessibilityLabel("Settings")
    }
    .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 8)
  }

  private var hero: some View {
    ZStack(alignment: .bottomLeading) {
      Landscape(mix: store.mix, animated: store.isPlaying)
        .frame(height: typeSize.isAccessibilitySize ? 240 : 292)
      LinearGradient(colors: [.clear, HushStyle.ink], startPoint: .center, endPoint: .bottom)
      VStack(alignment: .leading, spacing: 10) {
        Text("A LITTLE LESS WORLD")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .tracking(3).foregroundStyle(HushStyle.lavender)
        Text(store.preferences.sceneName)
          .font(.system(.largeTitle, design: .serif).weight(.regular))
          .tracking(-0.9)
        HStack(spacing: 7) {
          Circle().fill(store.isPlaying ? HushStyle.lavender : HushStyle.muted)
            .frame(width: 5, height: 5)
          Text(store.isPlaying ? "Here, for a while." : "Make room for quiet.")
            .font(.subheadline).foregroundStyle(HushStyle.muted)
        }
      }.padding(.horizontal, 28).padding(.bottom, 10)
    }
  }

  private var mixer: some View {
    VStack(spacing: 22) {
      HStack {
        Text("THE ELEMENTS")
          .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2.4)
          .foregroundStyle(HushStyle.muted)
        Spacer()
        Button {
          showReset = true
        } label: {
          Image(systemName: "arrow.counterclockwise").frame(width: 40, height: 44)
        }.accessibilityLabel("Clear mix")
        Button {
          sheet = .save
        } label: {
          Label("Save", systemImage: "bookmark")
            .font(.subheadline).frame(minHeight: 44)
        }.accessibilityLabel("Save scene")
      }
      HStack(alignment: .top, spacing: 12) {
        ForEach(Layer.allCases) { layer in
          SoundFader(
            layer: layer,
            level: Binding(get: { store.mix.level(layer) }, set: { store.setLevel(layer, $0) }))
        }
      }
      if let message = store.message {
        Text(message).font(.footnote).foregroundStyle(HushStyle.lavender)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityLabel(message)
      }
    }
    .padding(.horizontal, 28)
  }

  private var playbackDock: some View {
    VStack(spacing: 13) {
      HStack(spacing: 12) {
        Button {
          store.isMuted.toggle()
          store.haptic()
        } label: {
          Image(systemName: store.isMuted ? "speaker.slash" : "speaker.wave.2")
            .frame(width: 36, height: 44)
        }.accessibilityLabel(store.isMuted ? "Unmute all sounds" : "Mute all sounds")
        Slider(
          value: Binding(
            get: { store.mix.master },
            set: { store.preferences.mix.master = Mix.clamp($0) }
          )
        ).tint(HushStyle.lavender).accessibilityLabel("Master volume")
        Text("\(Int(store.mix.master * 100))")
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(HushStyle.muted).frame(width: 30)
      }
      HStack(spacing: 12) {
        Button {
          sheet = .timer
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "moon.zzz")
            Text(store.timerLabel).monospacedDigit()
          }.font(.subheadline).frame(maxWidth: .infinity, minHeight: 52)
        }
        .foregroundStyle(store.countdown == nil ? HushStyle.silver : HushStyle.lavender)
        .background(.white.opacity(0.045), in: Capsule())
        .accessibilityLabel(
          store.countdown == nil ? "Sleep timer" : "Sleep timer, \(store.timerLabel) remaining")
        Button {
          store.togglePlayback()
        } label: {
          HStack(spacing: 9) {
            Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
            Text(store.isPlaying ? "Pause" : "Listen")
          }.font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .foregroundStyle(HushStyle.ink).background(HushStyle.lavender, in: Capsule())
        .accessibilityLabel(store.isPlaying ? "Pause soundscape" : "Listen to soundscape")
      }
      if store.isPlaying {
        Button {
          if store.fadeStarted != nil { store.fadeStarted = nil } else { store.fadeOut() }
        } label: {
          Text(store.isFading ? "Fading into quiet · tap to keep listening" : "Fade to quiet")
            .font(.caption).foregroundStyle(HushStyle.muted).frame(minHeight: 30)
        }
        .disabled(store.isFading && store.fadeStarted == nil)
      }
    }
    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 6)
    .background {
      HushStyle.ink.opacity(0.97).ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.09)).frame(height: 0.5) }
    }
  }
}

enum HushSheet: String, Identifiable {
  case scenes, save, timer, settings
  var id: String { rawValue }
}

struct SoundFader: View {
  let layer: Layer
  @Binding var level: Double
  @EnvironmentObject private var store: HushStore

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: layer.symbol)
        .font(.system(size: 21, weight: .ultraLight))
        .foregroundStyle(level > 0 ? HushStyle.lavender : HushStyle.muted)
        .frame(height: 24).accessibilityHidden(true)
      GeometryReader { geometry in
        ZStack(alignment: .bottom) {
          Capsule().fill(.white.opacity(0.04))
          Capsule().fill(
            LinearGradient(
              colors: [HushStyle.lavender.opacity(0.12), HushStyle.lavender.opacity(0.45)],
              startPoint: .bottom, endPoint: .top)
          ).frame(height: max(0, geometry.size.height * level))
          ForEach(1..<5) { tick in
            Rectangle().fill(.white.opacity(0.08)).frame(width: 14, height: 1)
              .offset(y: -geometry.size.height * Double(tick) / 5)
          }
          Capsule().fill(level > 0 ? HushStyle.silver : HushStyle.muted)
            .frame(width: 24, height: 3)
            .shadow(color: HushStyle.lavender.opacity(0.5), radius: 10)
            .offset(y: -max(8, (geometry.size.height - 16) * level + 8))
        }
        .overlay(Capsule().stroke(.white.opacity(level > 0 ? 0.17 : 0.06), lineWidth: 1))
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              level = Mix.clamp(1 - value.location.y / geometry.size.height)
            }
            .onEnded { _ in store.haptic() }
        )
      }
      .frame(width: 48, height: 135)
      .accessibilityElement()
      .accessibilityLabel("\(layer.title) volume")
      .accessibilityValue("\(Int(level * 100)) percent")
      .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: level = Mix.clamp(level + 0.1)
        case .decrement: level = Mix.clamp(level - 0.1)
        @unknown default: break
        }
      }
      VStack(spacing: 4) {
        Text(layer.title).font(.subheadline)
        Text(level > 0 ? "\(Int(level * 100))%" : "OFF")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .tracking(1).foregroundStyle(HushStyle.muted)
      }
    }.frame(maxWidth: .infinity)
  }
}
