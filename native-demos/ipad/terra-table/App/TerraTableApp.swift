import SwiftUI
import UIKit

@main
struct TerraTableApp: App {
  var body: some Scene {
    WindowGroup {
      StudioView()
        .preferredColorScheme(.light)
        .statusBarHidden()
    }
  }
}

private enum Palette {
  static let paper = Color(red: 0.976, green: 0.973, blue: 0.957)
  static let studio = Color(red: 0.935, green: 0.935, blue: 0.910)
  static let ink = Color(red: 0.16, green: 0.21, blue: 0.18)
  static let muted = Color(red: 0.38, green: 0.42, blue: 0.38)
  static let green = Color(red: 0.20, green: 0.32, blue: 0.26)
  static let selected = Color(red: 0.88, green: 0.91, blue: 0.87)
  static let line = Color(red: 0.81, green: 0.83, blue: 0.78)
  static let water = Color(red: 0.26, green: 0.46, blue: 0.46)
}

private enum Type {
  static func text(_ size: CGFloat) -> Font {
    .custom("Georgia", size: size, relativeTo: .body)
  }

  static func emphasis(_ size: CGFloat) -> Font {
    .custom("Georgia-Bold", size: size, relativeTo: .body)
  }

  static func italic(_ size: CGFloat) -> Font {
    .custom("Georgia-Italic", size: size, relativeTo: .body)
  }

  static func title(_ size: CGFloat) -> Font {
    .custom("Georgia", size: size, relativeTo: .title)
  }
}

struct StudioView: View {
  @StateObject private var model = StudioModel()
  @StateObject private var capture = SceneCapture()
  @State private var libraryOpen = false
  @State private var exportOpen = false
  @State private var helpOpen = false
  @State private var exportedURL: URL?
  @State private var exportMessage = ""

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        header
        rule
        HStack(spacing: 0) {
          sidebar.frame(width: geometry.size.width > 1100 ? 264 : 238)
          Rectangle().fill(Palette.line).frame(width: 1)
          workspace
        }
        footer
      }
      .background(Palette.paper)
      .foregroundStyle(Palette.ink)
      .tint(Palette.green)
      .font(Type.text(15))
    }
    .sheet(isPresented: $libraryOpen) { library }
    .sheet(isPresented: $exportOpen) { exportSheet }
    .sheet(isPresented: $helpOpen) { guide }
    .alert(
      "Unable to complete the operation",
      isPresented: Binding(
        get: { model.error != nil }, set: { if !$0 { model.error = nil } }
      )
    ) {
      Button("Dismiss", role: .cancel) { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    ) { _ in
      model.end()
      model.persist()
    }
  }

  private var header: some View {
    HStack(spacing: 18) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Terra Table").font(Type.emphasis(25)).tracking(-1)
        Text("Landscape modelling").font(Type.italic(12)).foregroundStyle(Palette.muted)
      }
      .accessibilityElement(children: .combine)
      Spacer(minLength: 10)
      HStack(spacing: 0) {
        iconButton("arrow.uturn.backward", "Undo", disabled: model.history.undoStack.isEmpty) {
          model.undo()
        }
        .keyboardShortcut("z", modifiers: .command)
        iconButton("arrow.uturn.forward", "Redo", disabled: model.history.redoStack.isEmpty) {
          model.redo()
        }
        .keyboardShortcut("z", modifiers: [.command, .shift])
      }
      Rectangle().fill(Palette.line).frame(width: 1, height: 26)
      Button {
        libraryOpen = true
      } label: {
        Text("Library")
      }
      .buttonStyle(QuietButton())
      .accessibilityIdentifier("openLibrary")
      Button {
        model.save()
      } label: {
        Text("Save snapshot")
      }
      .buttonStyle(QuietButton())
      .keyboardShortcut("s", modifiers: .command)
      Button {
        exportedURL = nil
        exportMessage = ""
        exportOpen = true
      } label: {
        HStack(spacing: 10) {
          Text("Export")
          Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .medium))
        }
      }
      .buttonStyle(FilledButton())
    }
    .padding(.horizontal, 28)
    .frame(minHeight: 78)
  }

  private var sidebar: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Terrain tools")
            VStack(spacing: 2) {
              ForEach(Brush.allCases, id: \.self) { brush in
                brushButton(brush)
              }
            }
          }
          VStack(spacing: 14) {
            parameter("Radius", value: String(format: "%.1f", model.radius)) {
              Slider(value: $model.radius, in: 0.35...2.5)
                .accessibilityLabel("Brush radius")
            }
            parameter("Strength", value: "\(Int(model.strength * 100))%") {
              Slider(value: $model.strength, in: 0.1...1)
                .accessibilityLabel("Brush strength")
            }
          }
          .opacity(model.brush == .orbit ? 0.45 : 1)
          .disabled(model.brush == .orbit)
          rule
          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Starting landscapes")
            VStack(spacing: 4) {
              ForEach(Landscape.allCases, id: \.self) { preset in
                presetButton(preset)
              }
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
      }
      rule
      Button {
        helpOpen = true
      } label: {
        HStack(spacing: 10) {
          Image(systemName: "book.closed").font(.system(size: 15, weight: .light))
          Text("Studio guide").font(Type.text(14))
          Spacer()
          Image(systemName: "arrow.up.right").font(.system(size: 11))
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private func brushButton(_ brush: Brush) -> some View {
    let selected = model.brush == brush
    return Button {
      model.brush = brush
    } label: {
      HStack(spacing: 13) {
        Image(systemName: symbol(brush))
          .font(.system(size: 18, weight: .light))
          .frame(width: 25)
        Text(brush.rawValue).font(selected ? Type.emphasis(15) : Type.text(15))
        Spacer()
        if selected {
          Image(systemName: "checkmark").font(.system(size: 11, weight: .medium))
        }
      }
      .padding(.horizontal, 13)
      .frame(minHeight: 45)
      .background(selected ? Palette.selected : .clear)
      .overlay(alignment: .leading) {
        if selected { Rectangle().fill(Palette.green).frame(width: 2) }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("brush\(brush.rawValue)")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func presetButton(_ preset: Landscape) -> some View {
    Button {
      model.preset(preset)
    } label: {
      HStack(spacing: 11) {
        LandscapeSwatch(terrain: Terrain(landscape: preset))
          .frame(width: 49, height: 43)
          .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 0.5))
        VStack(alignment: .leading, spacing: 4) {
          Text(preset.rawValue).font(Type.text(14))
          Text(presetDetail(preset)).font(Type.italic(11)).foregroundStyle(Palette.muted)
        }
        Spacer(minLength: 0)
      }
      .padding(.vertical, 7)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Load \(preset.rawValue) preset")
  }

  private var workspace: some View {
    VStack(spacing: 0) {
      documentHeader
      ZStack {
        TerrainCanvas(model: model, capture: capture)
        VStack {
          Spacer()
          HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
              Text(model.contours ? "Elevation contours" : "Natural surface")
                .font(Type.text(13))
              Text(
                model.contours ? "50 m intervals · illustrative units" : "Moss, limestone & water"
              )
              .font(Type.italic(11)).foregroundStyle(Palette.muted)
            }
            .padding(12)
            .background(Palette.studio.opacity(0.94))
            .allowsHitTesting(false)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
              iconButton("minus", "Zoom out", disabled: model.zoom <= 0.7) {
                model.zoom = max(0.7, model.zoom - 0.15)
                model.status = "View scale \(Int(model.zoom * 100))%"
              }
              Text("\(Int(model.zoom * 100))%").font(Type.text(12)).monospacedDigit()
                .frame(minWidth: 40)
                .accessibilityLabel("View scale \(Int(model.zoom * 100)) percent")
              iconButton("plus", "Zoom in", disabled: model.zoom >= 1.8) {
                model.zoom = min(1.8, model.zoom + 0.15)
                model.status = "View scale \(Int(model.zoom * 100))%"
              }
              Rectangle().fill(Palette.line).frame(width: 1, height: 20)
              iconButton("viewfinder", "Reset view") {
                model.zoom = 1
                model.homeRevision += 1
                model.status = "Studio view restored · 100%"
              }
            }
            .background(Palette.paper)
            .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 0.5))
          }
          .padding(.horizontal, 22)
          .padding(.bottom, 18)
        }
      }
      waterPanel
    }
    .background(Palette.studio)
  }

  private var documentHeader: some View {
    HStack(alignment: .center, spacing: 20) {
      VStack(alignment: .leading, spacing: 9) {
        Text(model.terrain.title).font(Type.title(34)).tracking(-0.8)
          .accessibilityAddTraits(.isHeader)
        Text("Editable heightfield  ·  \(Terrain.resolution) × \(Terrain.resolution) samples")
          .font(Type.text(12)).foregroundStyle(Palette.muted)
      }
      Spacer(minLength: 0)
      HStack(spacing: 0) {
        modeButton("Natural", selected: !model.contours) { model.contours = false }
        modeButton("Contours", selected: model.contours) { model.contours = true }
      }
      .background(Palette.paper)
      .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 0.5))
    }
    .padding(.horizontal, 32)
    .padding(.top, 27)
    .padding(.bottom, 12)
  }

  private var waterPanel: some View {
    HStack(spacing: 23) {
      VStack(alignment: .leading, spacing: 9) {
        Text("Waterline").font(Type.text(16))
        Text("\(Int(model.terrain.water * 1000)) m")
          .font(Type.title(28)).monospacedDigit().foregroundStyle(Palette.water)
          .contentTransition(.numericText())
      }
      VStack(spacing: 5) {
        Slider(
          value: Binding(get: { model.terrain.water }, set: { model.setWater($0) }),
          in: 0...0.85,
          onEditingChanged: { editing in editing ? model.begin() : model.end() }
        )
        .tint(Palette.water)
        .accessibilityLabel("Water level")
        HStack {
          Text("0 m")
          Spacer()
          Text("Illustrative elevation")
          Spacer()
          Text("850 m")
        }
        .font(Type.text(11)).foregroundStyle(Palette.muted)
      }
      .frame(maxWidth: .infinity)
      Rectangle().fill(Palette.line).frame(width: 1, height: 48)
      metric("\(model.terrain.landPercent)%", caption: "Dry land")
      metric("\(model.terrain.summit) m", caption: "Summit")
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 22)
    .background(Palette.paper)
    .overlay(alignment: .top) { rule }
  }

  private var footer: some View {
    HStack(spacing: 12) {
      Text(model.status).lineLimit(1)
        .accessibilityIdentifier("studioStatus")
      Spacer(minLength: 10)
      Text(
        model.brush == .orbit
          ? "Drag to orbit · pinch to zoom"
          : "Drag on the surface to \(model.brush.rawValue.lowercased())"
      )
      .lineLimit(1)
      Rectangle().fill(Palette.line).frame(width: 1, height: 12)
      Text("On-device storage")
    }
    .font(Type.text(11)).foregroundStyle(Palette.muted)
    .padding(.horizontal, 28).frame(minHeight: 34)
    .overlay(alignment: .top) { rule }
  }

  private var library: some View {
    StudioSheet(
      title: "Landscape library",
      subtitle: "\(model.saved.count) saved snapshots · stored on this iPad"
    ) {
      if model.saved.isEmpty {
        VStack(alignment: .leading, spacing: 16) {
          LandscapeSwatch(terrain: model.terrain).frame(height: 180)
          Text("Keep a version of your landscape.").font(Type.title(24))
          Text(
            "Save a snapshot to preserve the current terrain and waterline. You can reopen it here at any time."
          )
          .foregroundStyle(Palette.muted).lineSpacing(5)
          Button {
            model.save()
          } label: {
            Text("Save current landscape")
          }.buttonStyle(FilledButton())
        }
      } else {
        ForEach(model.saved) { world in
          Button {
            model.reopen(world)
            libraryOpen = false
          } label: {
            HStack(spacing: 20) {
              LandscapeSwatch(terrain: world.terrain)
                .frame(width: 112, height: 92)
                .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 0.5))
              VStack(alignment: .leading, spacing: 9) {
                Text(world.terrain.title).font(Type.title(23))
                Text(world.date.formatted(date: .abbreviated, time: .shortened))
                  .font(Type.text(13)).foregroundStyle(Palette.muted)
                Text(
                  "\(world.terrain.landPercent)% dry land · waterline \(Int(world.terrain.water * 1000)) m"
                )
                .font(Type.text(12)).foregroundStyle(Palette.muted)
              }
              Spacer(minLength: 0)
              Image(systemName: "arrow.up.right").font(.system(size: 15, weight: .light))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(
            "Reopen \(world.terrain.title), \(world.date.formatted(date: .abbreviated, time: .shortened))"
          )
          rule
        }
        Text("Reopening replaces the active landscape. Undo returns to your previous terrain.")
          .font(Type.italic(13)).foregroundStyle(Palette.muted).lineSpacing(4)
      }
    } close: {
      libraryOpen = false
    }
  }

  private var exportSheet: some View {
    StudioSheet(
      title: "Export landscape",
      subtitle: model.terrain.title
    ) {
      Text("Choose a deliverable").font(Type.title(24))
      exportOption(
        title: "Terrain mesh", format: "OBJ",
        detail: "6,561 vertices · 12,800 triangles\nAn open surface for 3D modelling tools.",
        symbol: "cube.transparent"
      ) {
        exportedURL = model.exportMesh()
        exportMessage =
          exportedURL == nil
          ? "The mesh could not be exported. Check available storage and try again."
          : "Terrain mesh ready."
      }
      rule
      exportOption(
        title: "Diorama image", format: "PNG",
        detail:
          "The current camera and surface mode.\nFull-resolution image without studio controls.",
        symbol: "photo"
      ) {
        do {
          exportedURL = try capture.exportImage()
          exportMessage = "Diorama image ready."
        } catch {
          exportedURL = nil
          exportMessage = "The image could not be exported: \(error.localizedDescription)"
        }
      }
      rule
      if !exportMessage.isEmpty {
        VStack(alignment: .leading, spacing: 16) {
          Text(exportMessage).font(Type.emphasis(15))
          if let exportedURL {
            ShareLink(item: exportedURL) {
              Label("Share or Save to Files", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(FilledButton())
          }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.selected)
        .accessibilityIdentifier("exportResult")
      }
      VStack(alignment: .leading, spacing: 9) {
        Text("Export details").font(Type.emphasis(14))
        Text(
          "Files are saved in Terra Table → Exports in the Files app. Each export replaces the previous file of that format."
        )
        Text(
          "The mesh contains the terrain surface only. Water, plinth and materials are presentation elements."
        )
      }
      .font(Type.text(13)).foregroundStyle(Palette.muted).lineSpacing(5)
    } close: {
      exportOpen = false
    }
  }

  private func exportOption(
    title: String, format: String, detail: String, symbol: String, action: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top, spacing: 18) {
        Image(systemName: symbol).font(.system(size: 28, weight: .ultraLight))
          .frame(width: 34)
        VStack(alignment: .leading, spacing: 9) {
          Text(title).font(Type.title(23))
          Text(detail).font(Type.text(14)).foregroundStyle(Palette.muted).lineSpacing(5)
        }
        Spacer(minLength: 0)
        Text(format).font(Type.emphasis(12)).foregroundStyle(Palette.muted)
      }
      Button(action: action) {
        Text("Export \(format)")
      }
      .buttonStyle(QuietButton())
      .accessibilityLabel("Export \(title.lowercased()) (\(format.lowercased()))")
    }
    .padding(.vertical, 8)
  }

  private var guide: some View {
    StudioSheet(
      title: "Studio guide",
      subtitle: "Tools, navigation & file management"
    ) {
      guideStep(
        "Shape the terrain",
        "Raise adds height; Carve removes it. Smooth softens a rough ridge. Select a tool and drag on the surface, or tap for a small adjustment. Radius sets the area of influence; Strength controls the amount of change."
      )
      guideStep(
        "Set the waterline",
        "Drag the Waterline slider to submerge low ground. All basins below the selected elevation fill, including disconnected lakes. Dry land and summit readouts update as you work."
      )
      guideStep(
        "Navigate the model",
        "Select Orbit and drag horizontally to rotate, or vertically to tilt. Pinch or use the + and − controls to zoom. Reset view restores the original camera and 100% scale."
      )
      guideStep(
        "Read elevation",
        "Contours marks elevation at 50 illustrative metre intervals. Natural restores the unmarked surface. The mesh has 81 × 81 samples; exported vertical coordinates are exaggerated for presentation."
      )
      guideStep(
        "Manage versions",
        "Each stroke, water adjustment and loaded preset can be undone. Save snapshot keeps a version in Library; reopening it is also undoable. The active terrain saves automatically. Export writes an OBJ mesh or a PNG of the current view."
      )
      VStack(alignment: .leading, spacing: 10) {
        Text("Keyboard shortcuts").font(Type.title(22))
        shortcut("Save snapshot", keys: "⌘ S")
        shortcut("Undo", keys: "⌘ Z")
        shortcut("Redo", keys: "⇧ ⌘ Z")
      }
      rule
      Text(
        "Terra Table is a creative heightfield model. Elevation units are illustrative; it does not simulate erosion, drainage or overhangs. All computation and storage stay on this device."
      )
      .font(Type.italic(13)).foregroundStyle(Palette.muted).lineSpacing(5)
    } close: {
      helpOpen = false
    }
  }

  private func guideStep(_ title: String, _ detail: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).font(Type.title(23))
      Text(detail).font(Type.text(15)).foregroundStyle(Palette.muted).lineSpacing(6)
      rule.padding(.top, 7)
    }
  }

  private func shortcut(_ title: String, keys: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(keys)
    }
    .font(Type.text(14)).foregroundStyle(Palette.muted)
  }

  private var rule: some View {
    Rectangle().fill(Palette.line).frame(height: 0.5)
  }

  private func symbol(_ brush: Brush) -> String {
    switch brush {
    case .raise: return "arrow.up.to.line"
    case .lower: return "arrow.down.to.line"
    case .smooth: return "water.waves"
    case .orbit: return "rotate.3d"
    }
  }

  private func presetDetail(_ landscape: Landscape) -> String {
    switch landscape {
    case .alpine: return "Ridges & foothills"
    case .caldera: return "Volcanic basin"
    case .archipelago: return "Island group"
    }
  }

  private func sectionHeading(_ title: String) -> some View {
    Text(title).font(Type.emphasis(14)).foregroundStyle(Palette.ink)
      .accessibilityAddTraits(.isHeader)
  }

  private func metric(_ value: String, caption: String) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(caption).font(Type.text(12)).foregroundStyle(Palette.muted)
      Text(value).font(Type.title(26)).monospacedDigit()
    }
    .fixedSize(horizontal: true, vertical: false)
    .accessibilityElement(children: .combine)
  }

  private func parameter<Control: View>(
    _ title: String, value: String, @ViewBuilder control: () -> Control
  ) -> some View {
    VStack(spacing: 5) {
      HStack {
        Text(title).font(Type.text(14))
        Spacer()
        Text(value).font(Type.emphasis(13)).monospacedDigit()
      }
      control()
    }
  }

  private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Text(title).font(selected ? Type.emphasis(13) : Type.text(13))
        .padding(.horizontal, 18).frame(minHeight: 44)
        .foregroundStyle(selected ? Palette.ink : Palette.muted)
        .background(selected ? Palette.selected : .clear)
        .overlay(alignment: .bottom) {
          if selected { Rectangle().fill(Palette.green).frame(height: 2) }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func iconButton(
    _ symbol: String, _ label: String, disabled: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 16, weight: .light))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain).accessibilityLabel(label).help(label)
    .disabled(disabled).opacity(disabled ? 0.3 : 1)
  }
}

private struct QuietButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(Type.text(14))
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 17).frame(minHeight: 44)
      .background(configuration.isPressed ? Palette.selected : Palette.paper)
      .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 0.5))
      .contentShape(Rectangle())
  }
}

private struct FilledButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(Type.text(14))
      .padding(.horizontal, 20).frame(minHeight: 44).foregroundStyle(Palette.paper)
      .background(Palette.green.opacity(configuration.isPressed ? 0.8 : 1))
      .contentShape(Rectangle())
  }
}

private struct StudioSheet<Content: View>: View {
  let title: String
  let subtitle: String
  @ViewBuilder let content: () -> Content
  let close: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center, spacing: 20) {
        VStack(alignment: .leading, spacing: 10) {
          Text(title).font(Type.title(30)).tracking(-0.5).accessibilityAddTraits(.isHeader)
          Text(subtitle).font(Type.text(13)).foregroundStyle(Palette.muted)
        }
        Spacer(minLength: 0)
        Button("Done", action: close).buttonStyle(QuietButton())
      }
      .padding(30)
      Rectangle().fill(Palette.line).frame(height: 0.5)
      ScrollView {
        VStack(alignment: .leading, spacing: 24, content: content)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(30)
      }
    }
    .font(Type.text(15))
    .foregroundStyle(Palette.ink)
    .tint(Palette.green)
    .background(Palette.paper)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(12)
  }
}

private struct LandscapeSwatch: View {
  let terrain: Terrain

  var body: some View {
    Canvas { context, size in
      let n = Terrain.resolution
      let cell = CGSize(width: size.width / CGFloat(n), height: size.height / CGFloat(n))
      for z in 0..<n {
        for x in 0..<n {
          let h = terrain.heights[z * n + x]
          let color: Color
          if h < terrain.water {
            color = Color(red: 0.43, green: 0.61, blue: 0.59)
          } else {
            let contour = Int(h * 1000) % 80 < 9
            let shade = contour ? 0.08 : 0
            color = Color(
              red: Double(0.47 + h * 0.43) - shade,
              green: Double(0.53 + h * 0.34) - shade,
              blue: Double(0.38 + h * 0.48) - shade)
          }
          context.fill(
            Path(
              CGRect(
                x: CGFloat(x) * cell.width, y: CGFloat(z) * cell.height,
                width: cell.width + 0.5, height: cell.height + 0.5)),
            with: .color(color))
        }
      }
    }
    .accessibilityHidden(true)
  }
}
