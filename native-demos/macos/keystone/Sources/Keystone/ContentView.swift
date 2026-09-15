import KeystoneCore
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var studio: Studio
  @State private var workspace = "Drawing"
  @State private var inspectorTab = "Inspect"
  @State private var showProject = false

  var body: some View {
    VStack(spacing: 0) {
      header.fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 0) {
        projectRail.frame(width: 216)
        VStack(spacing: 0) {
          workspaceBar
          if workspace == "Drawing" { drawing } else { ResultSchedule() }
          metrics
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        Rectangle().fill(Ink.line).frame(width: 1)
        inspector.frame(width: 276)
      }.frame(maxHeight: .infinity).clipped()
      footer.fixedSize(horizontal: false, vertical: true)
    }
    .background(Ink.paper).foregroundStyle(Ink.navy).buttonStyle(.plain)
    .onChange(of: studio.selection) { _, selection in
      if selection != nil { inspectorTab = "Inspect" }
    }
    .sheet(isPresented: $showProject) { ProjectDetails().environmentObject(studio) }
    .alert(
      "Keystone",
      isPresented: Binding(
        get: { studio.errorMessage != nil }, set: { if !$0 { studio.errorMessage = nil } }
      )
    ) {
      Button("OK") { studio.errorMessage = nil }
    } message: {
      Text(studio.errorMessage ?? "")
    }
  }

  private var header: some View {
    HStack(spacing: 14) {
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .font(.system(size: 30, weight: .ultraLight)).foregroundStyle(Ink.sand)
      VStack(alignment: .leading, spacing: 4) {
        Text("KEYSTONE").font(.system(size: 21, design: .serif)).tracking(4)
        Text("STRUCTURAL DESIGN STUDIO").font(.system(size: 8, weight: .medium)).tracking(1.7)
          .foregroundStyle(.white.opacity(0.5))
      }
      Rectangle().fill(.white.opacity(0.14)).frame(width: 1, height: 30).padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 5) {
        Text(studio.documentURL?.lastPathComponent ?? "Untitled study")
          .font(.system(size: 12, weight: .medium)).lineLimit(1)
        Text(studio.isDirty ? "Local autosave · unsaved file changes" : "Saved to file")
          .font(.system(size: 10)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
      }
      Spacer(minLength: 10)
      Button(action: studio.open) { Label("Open", systemImage: "folder").padding(10) }
      Menu {
        Button("Save", action: studio.save)
        Button("Save as…", action: studio.saveAs)
      } label: {
        Label("Save", systemImage: "square.and.arrow.down").foregroundStyle(.white)
      }.menuStyle(.borderlessButton).environment(\.colorScheme, .dark).fixedSize().padding(10)
      Menu {
        Button("Engineering report · HTML") { studio.export(report: true) }
        Button("Vector drawing · SVG") { studio.export(report: false) }
        Button("Member & reaction schedule · CSV", action: studio.exportCSV)
      } label: {
        Label("Export", systemImage: "arrow.up.right")
      }.menuStyle(.borderlessButton).environment(\.colorScheme, .light).fixedSize()
        .padding(.horizontal, 16).padding(.vertical, 11)
        .background(Ink.sand, in: RoundedRectangle(cornerRadius: 6))
    }
    .font(.system(size: 12)).foregroundStyle(.white)
    .padding(.horizontal, 25).padding(.top, 25).padding(.bottom, 18).background(Ink.navy)
  }

  private var projectRail: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
          railLabel("01 / PROJECT")
          Button {
            showProject = true
          } label: {
            VStack(alignment: .leading, spacing: 9) {
              Text(studio.design.name).font(.system(size: 22, design: .serif))
                .lineLimit(4).multilineTextAlignment(.leading).lineSpacing(3)
              Label("Project details", systemImage: "pencil").font(.system(size: 10))
                .foregroundStyle(Ink.sand)
            }
          }.accessibilityLabel("Edit project details")
          Text(String(format: "%.1f m span  /  %.0f kg", studio.design.spanM, studio.design.massKg))
            .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.55))
        }
        Rectangle().fill(.white.opacity(0.13)).frame(height: 1)
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            railLabel("02 / LOAD CASES")
            Spacer()
            Menu {
              Button("New empty case") { studio.addCase(duplicate: false) }
              Button("Duplicate active case") { studio.addCase(duplicate: true) }
              Divider()
              Button("Remove active case", action: studio.removeCase)
                .disabled(studio.design.activeCaseID == "service")
            } label: {
              Image(systemName: "plus").foregroundStyle(Ink.sand).frame(width: 24, height: 24)
            }.menuStyle(.borderlessButton).environment(\.colorScheme, .dark).fixedSize()
              .accessibilityLabel("Load case actions")
          }
          ForEach(studio.design.loadCases) { loadCase in
            let active = loadCase.id == studio.design.activeCaseID
            Button {
              studio.selectCase(loadCase.id)
            } label: {
              HStack(spacing: 10) {
                Image(systemName: "arrow.down.right").font(.system(size: 12))
                VStack(alignment: .leading, spacing: 5) {
                  Text(loadCase.name).font(.system(size: 12, weight: .medium))
                    .lineLimit(2).multilineTextAlignment(.leading)
                  Text(
                    String(format: "×%.2f", loadCase.factor)
                      + (loadCase.includesSelfWeight ? "  + self-weight" : "  nodal loads")
                  )
                  .font(.system(size: 9, design: .monospaced)).opacity(0.6)
                }
                Spacer(minLength: 0)
                if active { Circle().fill(Ink.copper).frame(width: 5, height: 5) }
              }.padding(12).foregroundStyle(active ? Ink.navy : .white.opacity(0.75))
                .background(
                  active ? Ink.paper : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
            }.accessibilityLabel("Activate \(loadCase.name)")
          }
          CaseEditor()
        }
        Rectangle().fill(.white.opacity(0.13)).frame(height: 1)
        VStack(alignment: .leading, spacing: 12) {
          railLabel("03 / STARTING POINTS")
          template("Warren", height: 3, detail: "Balanced")
          template("Highline", height: 4.5, detail: "Deep span")
          template("Low profile", height: 1.5, detail: "Slender")
        }
        VStack(alignment: .leading, spacing: 7) {
          Text("Resolve the forces.\nRefine the structure.")
            .font(.system(size: 16, design: .serif)).lineSpacing(3)
          Text("LOCAL WORKSPACE / SI UNITS").font(.system(size: 8, design: .monospaced))
            .foregroundStyle(.white.opacity(0.4))
        }.padding(.top, 4)
      }.padding(20).foregroundStyle(.white)
    }.background(Ink.navy)
  }

  private func railLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .medium, design: .monospaced))
      .tracking(0.5).foregroundStyle(.white.opacity(0.45))
  }

  private func template(_ name: String, height: Double, detail: String) -> some View {
    Button {
      studio.example(height, name: "\(name) / River crossing")
      workspace = "Drawing"
    } label: {
      HStack(spacing: 10) {
        MiniTruss(rise: height, color: Ink.sand).frame(width: 53, height: 28)
        VStack(alignment: .leading, spacing: 4) {
          Text(name).font(.system(size: 11, weight: .medium))
          Text("\(detail) · \(String(format: "%.1f", height)) m").font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.45))
        }
        Spacer(minLength: 0)
        Image(systemName: "arrow.up.right").font(.system(size: 9)).foregroundStyle(Ink.sand)
      }.padding(.vertical, 6)
    }.accessibilityLabel("Load \(name) example")
  }

  private var workspaceBar: some View {
    HStack(spacing: 4) {
      ForEach(["Drawing", "Schedules"], id: \.self) { tab in
        Button {
          workspace = tab
        } label: {
          Label(tab, systemImage: tab == "Drawing" ? "square.and.pencil" : "tablecells")
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 12).padding(.vertical, 10)
            .foregroundStyle(workspace == tab ? Ink.navy : Ink.muted)
            .background(
              workspace == tab ? Ink.line.opacity(0.35) : .clear,
              in: RoundedRectangle(cornerRadius: 5))
        }.accessibilityLabel("\(tab) workspace")
      }
      Spacer()
      Text(studio.result == nil ? "MODEL" : "LIVE ANALYSIS")
        .font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(1)
        .foregroundStyle(studio.result == nil ? Ink.muted : Ink.green)
      Circle().fill(studio.result == nil ? Ink.muted : Ink.green).frame(width: 5, height: 5)
    }.padding(.horizontal, 16).padding(.vertical, 8).background(Ink.panel)
      .overlay(alignment: .bottom) { Rectangle().fill(Ink.line).frame(height: 1) }
  }

  private var drawing: some View {
    VStack(spacing: 0) {
      HStack(spacing: 2) {
        ForEach(EditorTool.allCases, id: \.self) { tool in
          Button {
            studio.tool = tool
            studio.startNode = nil
            if tool == .node || tool == .member || tool == .load { studio.mode = .geometry }
          } label: {
            Label(tool.rawValue, systemImage: tool.icon).font(.system(size: 10, weight: .medium))
              .padding(.horizontal, 9).padding(.vertical, 9)
              .background(
                studio.tool == tool ? Ink.navy : .clear, in: RoundedRectangle(cornerRadius: 4)
              )
              .foregroundStyle(studio.tool == tool ? Ink.paper : Ink.muted)
          }.help(tool.hint).accessibilityLabel("\(tool.rawValue) tool")
        }
        Spacer(minLength: 2)
        Button(action: studio.undo) {
          Image(systemName: "arrow.uturn.backward").frame(width: 28, height: 30)
        }
        .disabled(!studio.canUndo).opacity(studio.canUndo ? 1 : 0.3).help("Undo · ⌘Z")
        .accessibilityLabel("Undo")
        Button(action: studio.redo) {
          Image(systemName: "arrow.uturn.forward").frame(width: 28, height: 30)
        }
        .disabled(!studio.canRedo).opacity(studio.canRedo ? 1 : 0.3).help("Redo · ⇧⌘Z")
        .accessibilityLabel("Redo")
      }.padding(.horizontal, 14).padding(.vertical, 4)
      ZStack(alignment: .topLeading) {
        DraftingCanvas().clipped()
        VStack(alignment: .leading, spacing: 7) {
          Eyebrow(text: "STRUCTURAL STUDY / \(studio.mode.rawValue.uppercased())")
          Text(studio.design.name.components(separatedBy: " / ").last ?? studio.design.name)
            .font(.system(size: 29, design: .serif)).lineLimit(1)
          Text(
            "\(studio.design.nodes.count) JOINTS  ·  \(studio.design.members.count) MEMBERS  ·  \(studio.design.activeCase.name.uppercased())"
          )
          .font(.system(size: 9, design: .monospaced)).foregroundStyle(Ink.muted).lineLimit(1)
        }.padding(.horizontal, 26).padding(.top, 14).allowsHitTesting(false)
        VStack {
          Spacer()
          if let error = studio.analysisError {
            HStack(spacing: 10) {
              Image(systemName: "exclamationmark.triangle")
              VStack(alignment: .leading, spacing: 4) {
                Text("ANALYSIS UNAVAILABLE").font(.system(size: 10, weight: .bold)).tracking(1)
                Text(error).font(.system(size: 10)).fixedSize(horizontal: false, vertical: true)
              }
              Spacer(minLength: 0)
              Button("Undo", action: studio.undo).font(.system(size: 11)).disabled(!studio.canUndo)
            }.foregroundStyle(Ink.copper).padding(13).background(
              Ink.panel, in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Ink.copper.opacity(0.25)))
            .padding(.horizontal, 18)
          }
          HStack(spacing: 14) {
            if studio.mode != .geometry, studio.result != nil {
              legend("TENSION", Ink.copper)
              legend("COMPRESSION", Ink.blue)
              if studio.mode == .deflection {
                Text("×\(Int(studio.deformationScale))").font(.system(size: 9, design: .monospaced))
              }
            } else {
              Text(studio.tool.hint).font(.system(size: 10)).foregroundStyle(Ink.muted).lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
              Button {
                studio.zoom = max(0.5, studio.zoom - 0.25)
              } label: {
                Image(systemName: "minus").frame(width: 25, height: 26)
              }.accessibilityLabel("Zoom out")
              Button(action: studio.fitDrawing) {
                Text(studio.zoom == 1 && studio.pan == .zero ? "Fit" : "\(Int(studio.zoom * 100))%")
                  .font(.system(size: 10, design: .monospaced)).frame(width: 39)
              }.accessibilityLabel("Fit drawing")
              Button {
                studio.zoom = min(3, studio.zoom + 0.25)
              } label: {
                Image(systemName: "plus").frame(width: 25, height: 26)
              }.accessibilityLabel("Zoom in")
            }.background(Ink.panel, in: RoundedRectangle(cornerRadius: 4))
              .overlay(RoundedRectangle(cornerRadius: 4).stroke(Ink.line))
          }.padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 12)
        }.frame(maxWidth: .infinity)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func legend(_ title: String, _ color: Color) -> some View {
    HStack(spacing: 5) {
      Capsule().fill(color).frame(width: 16, height: 3)
      Text(title).font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundStyle(
        Ink.muted)
    }
  }

  private var inspector: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        ForEach(["Inspect", "Checks"], id: \.self) { tab in
          Button {
            inspectorTab = tab
          } label: {
            Text(tab).font(.system(size: 11, weight: .medium)).frame(maxWidth: .infinity)
              .padding(.vertical, 17).foregroundStyle(inspectorTab == tab ? Ink.navy : Ink.muted)
              .overlay(alignment: .bottom) {
                Rectangle().fill(inspectorTab == tab ? Ink.copper : .clear).frame(height: 2)
              }
          }.accessibilityLabel("\(tab) panel")
        }
      }.background(Ink.panel)
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Button(action: studio.applyLoad) {
            HStack {
              Image(systemName: "waveform.path")
              Text(studio.analyzed ? "Recalculate" : "Run analysis").fontWeight(.semibold)
              Spacer()
              Image(systemName: "arrow.right")
            }.font(.system(size: 12)).padding(14).foregroundStyle(.white)
              .background(Ink.copper, in: RoundedRectangle(cornerRadius: 6))
          }.accessibilityIdentifier("applyLoad").accessibilityLabel("Run analysis")
          if inspectorTab == "Checks" {
            StudyChecks()
          } else {
            viewControls
            Divider()
            SelectionInspector()
            Divider()
            MaterialInspector()
          }
          Text(
            "PRELIMINARY 2D TRUSS STUDY\nIdeal joints · linear elastic members\nNo design-code certification"
          )
          .font(.system(size: 9)).foregroundStyle(Ink.muted).lineSpacing(4)
        }.padding(18)
      }
    }.background(Ink.panel.opacity(0.6))
  }

  private var viewControls: some View {
    VStack(alignment: .leading, spacing: 12) {
      Eyebrow(text: "DISPLAY")
      HStack(spacing: 0) {
        ForEach(DisplayMode.allCases, id: \.self) { mode in
          Button {
            studio.mode = mode
            if mode != .geometry, !studio.analyzed {
              studio.analyzed = true
              studio.solve()
            }
          } label: {
            Text(mode.rawValue).font(.system(size: 10, weight: .medium)).frame(maxWidth: .infinity)
              .padding(.vertical, 9).background(studio.mode == mode ? Ink.navy : .clear)
              .foregroundStyle(studio.mode == mode ? .white : Ink.muted)
          }.accessibilityLabel("\(mode.rawValue) view")
        }
      }.background(Ink.line.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 5))
      HStack {
        Toggle("Grid", isOn: $studio.showGrid)
        Spacer()
        Toggle("Labels", isOn: $studio.showLabels)
      }.toggleStyle(.checkbox).font(.system(size: 11))
      Toggle("Support reactions", isOn: $studio.showReactions).toggleStyle(.checkbox).font(
        .system(size: 11))
      if studio.mode == .deflection {
        Picker("Magnification", selection: $studio.deformationScale) {
          ForEach([1.0, 10, 50, 100, 250, 500], id: \.self) { Text("×\(Int($0))").tag($0) }
        }.font(.system(size: 11))
        Text("Dashed = original geometry").font(.system(size: 10)).foregroundStyle(Ink.muted)
      }
    }
  }

  private var metrics: some View {
    HStack(spacing: 0) {
      metric(
        "DISPLACEMENT", studio.result.map { String(format: "%.2f", $0.maxDisplacementMM) } ?? "—",
        "mm", Ink.navy)
      Rectangle().fill(Ink.line).frame(width: 1, height: 44)
      metric(
        (studio.result?.missingBucklingChecks ?? 0) > 0 ? "D/C · INCOMPLETE" : "DEMAND / CAPACITY",
        studio.result.map { String(format: "%.0f", $0.maxCapacityUtilization * 100) } ?? "—", "%",
        (studio.result?.maxCapacityUtilization ?? 0) > 1 ? Ink.copper : Ink.navy)
      Rectangle().fill(Ink.line).frame(width: 1, height: 44)
      metric("MATERIAL COST", String(format: "%.0f", studio.design.cost), "$", Ink.navy)
    }.padding(.vertical, 18).background(Ink.panel)
      .overlay(alignment: .top) { Rectangle().fill(Ink.line).frame(height: 1) }
  }

  private func metric(_ title: String, _ value: String, _ unit: String, _ color: Color) -> some View
  {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.system(size: 8, weight: .medium)).tracking(0.8).foregroundStyle(Ink.muted)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(value).font(.system(size: 29, weight: .light, design: .rounded)).monospacedDigit()
          .foregroundStyle(color)
        Text(unit).font(.system(size: 11)).foregroundStyle(Ink.muted)
      }
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
  }

  private var footer: some View {
    HStack {
      Circle().fill(studio.analysisError == nil ? Ink.green : Ink.copper).frame(width: 5, height: 5)
      Text(studio.notice).lineLimit(1)
      Spacer()
      Text("0.5 m SNAP  /  SI UNITS  /  KEYSTONE 2.0")
        .font(.system(size: 8, design: .monospaced)).tracking(0.3)
    }.font(.system(size: 9)).foregroundStyle(Ink.muted)
      .padding(.horizontal, 22).padding(.vertical, 10)
      .overlay(alignment: .top) { Rectangle().fill(Ink.line).frame(height: 1) }
  }
}

struct MiniTruss: View {
  var rise: Double
  var color = Ink.navy
  var body: some View {
    Canvas { context, size in
      let y = size.height - 4
      let top = y - rise * 5
      var path = Path()
      path.move(to: CGPoint(x: 0, y: y))
      path.addLine(to: CGPoint(x: size.width, y: y))
      for i in 0..<4 {
        let x = size.width * Double(i) / 4
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + size.width / 8, y: top))
        path.addLine(to: CGPoint(x: x + size.width / 4, y: y))
      }
      path.move(to: CGPoint(x: size.width / 8, y: top))
      path.addLine(to: CGPoint(x: size.width * 7 / 8, y: top))
      context.stroke(path, with: .color(color), lineWidth: 1.2)
    }
  }
}
