import SwiftUI

private enum Tool: String, CaseIterable {
  case looks = "Looks"
  case light = "Light"
  case color = "Color"
  case detail = "Detail"
  case crop = "Crop"
  var icon: String {
    switch self {
    case .looks: "camera.filters"
    case .light: "sun.max"
    case .color: "circle.lefthalf.filled"
    case .detail: "triangle"
    case .crop: "crop"
    }
  }
  var adjustments: [Adjustment] {
    switch self {
    case .light: [.exposure, .contrast, .highlights, .shadows]
    case .color: [.warmth, .saturation, .vibrance]
    case .detail: [.sharpness, .vignette]
    default: [.exposure]
    }
  }
}

private enum Adjustment: String, CaseIterable {
  case exposure = "Exposure"
  case contrast = "Contrast"
  case highlights = "Highlights"
  case shadows = "Shadows"
  case warmth = "Warmth"
  case saturation = "Saturation"
  case vibrance = "Vibrance"
  case sharpness = "Sharpness"
  case vignette = "Vignette"
  var key: WritableKeyPath<Edit, Double> {
    switch self {
    case .exposure: \.exposure
    case .contrast: \.contrast
    case .highlights: \.highlights
    case .shadows: \.shadows
    case .warmth: \.warmth
    case .saturation: \.saturation
    case .vibrance: \.vibrance
    case .sharpness: \.sharpness
    case .vignette: \.vignette
    }
  }
  var range: ClosedRange<Double> {
    switch self {
    case .exposure: -2...2
    case .contrast: 0.5...1.5
    case .saturation: 0...2
    case .sharpness, .vignette: 0...1
    default: -1...1
    }
  }
  var neutral: Double { self == .contrast || self == .saturation ? 1 : 0 }
  var hint: String {
    switch self {
    case .exposure: "Shape the overall light."
    case .contrast: "Give light and dark their distance."
    case .highlights: "Refine the brightest tones."
    case .shadows: "Bring depth out of the dark."
    case .warmth: "From cool air to golden light."
    case .saturation: "Set the strength of every color."
    case .vibrance: "Lift quieter colors with restraint."
    case .sharpness: "Define the fine details."
    case .vignette: "Draw the eye toward the center."
    }
  }
  func display(_ value: Double) -> String {
    self == .exposure ? String(format: "%+.2f", value) : String(format: "%.0f", value * 100)
  }
  func inputValue(_ text: String) -> Double? {
    guard let number = Double(text.replacingOccurrences(of: ",", with: ".")), number.isFinite else {
      return nil
    }
    let value = self == .exposure ? number : number / 100
    return range.contains(value) ? value : nil
  }
}

struct DarkroomView: View {
  @StateObject private var store = EditorStore()
  @State private var editing = false
  @State private var tool: Tool = .looks
  @State private var adjustment: Adjustment = .exposure
  @State private var comparing = false
  @State private var split = false
  @State private var splitPosition: CGFloat = 0.5
  @State private var resetting = false
  @State private var exportSheet = false
  @State private var information = false
  @State private var numericEntry = false
  @State private var numericText = ""
  @State private var panStart: Edit?
  @State private var showHistogram = true

  var body: some View {
    ZStack {
      ink.ignoresSafeArea()
      if editing {
        workspace.transition(.opacity)
      } else {
        LibraryView(store: store) { photo in
          store.select(photo)
          withAnimation(.easeInOut(duration: 0.22)) { editing = true }
        }.transition(.opacity)
      }
      if let notice = store.notice {
        VStack {
          Spacer()
          Label(notice, systemImage: "checkmark.circle.fill")
            .font(.system(size: 12, weight: .medium)).padding(14)
            .background(.ultraThinMaterial, in: Capsule()).padding(.bottom, 15)
        }.allowsHitTesting(false)
      }
    }
    .foregroundStyle(paper).tint(amber).preferredColorScheme(.dark)
    .sheet(isPresented: $exportSheet) { ExportStudioView(store: store) }
    .sheet(isPresented: $information) { photoInformation }
    .alert(
      "Studio notice",
      isPresented: Binding(
        get: { store.error != nil && !exportSheet }, set: { if !$0 { store.error = nil } })
    ) {
      Button("Continue", role: .cancel) { store.error = nil }
    } message: {
      Text(store.error ?? "")
    }
    .alert("Set \(adjustment.rawValue.lowercased())", isPresented: $numericEntry) {
      TextField("Value", text: $numericText).keyboardType(.numbersAndPunctuation)
      Button("Cancel", role: .cancel) {}
      Button("Apply") {
        if let value = adjustment.inputValue(numericText) {
          store.change { $0[keyPath: adjustment.key] = value }
        } else {
          store.error =
            "Enter a number from \(adjustment.display(adjustment.range.lowerBound)) "
            + "to \(adjustment.display(adjustment.range.upperBound))."
        }
      }
    } message: {
      Text(
        "\(adjustment.display(adjustment.range.lowerBound)) to \(adjustment.display(adjustment.range.upperBound))"
          + (adjustment == .exposure ? " EV" : ""))
    }
    .confirmationDialog(
      "Reset this photograph?", isPresented: $resetting, titleVisibility: .visible
    ) {
      Button("Reset all edits", role: .destructive) { store.change { $0 = Edit() } }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your original stays untouched. You can undo the reset.")
    }
    .onChange(of: tool) { _, value in
      adjustment = value.adjustments[0]
      if value == .crop { split = false }
    }
  }

  private var workspace: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          toolbar
          photoTitle
          canvas.frame(height: max(230, geometry.size.height - 388))
          imageToolbar
          toolPicker
          controls.frame(height: 157)
          footer
        }.frame(minHeight: geometry.size.height, alignment: .top)
      }.scrollIndicators(.hidden)
    }
  }

  private var toolbar: some View {
    HStack(spacing: 0) {
      IconButton(icon: "chevron.left", label: "Back to library") {
        store.commit()
        store.refreshLibrary()
        withAnimation(.easeInOut(duration: 0.22)) { editing = false }
      }.accessibilityIdentifier("back-to-library")
      Text("afterglow").font(.system(size: 22, design: .serif)).tracking(-1)
      Spacer(minLength: 4)
      IconButton(icon: "arrow.uturn.backward", label: "Undo") { store.undo() }
        .disabled(!store.history.canUndo).opacity(store.history.canUndo ? 1 : 0.25)
        .accessibilityIdentifier("undo")
      IconButton(icon: "arrow.uturn.forward", label: "Redo") { store.redo() }
        .disabled(!store.history.canRedo).opacity(store.history.canRedo ? 1 : 0.25)
        .accessibilityIdentifier("redo")
      Button {
        store.exported = nil
        exportSheet = true
      } label: {
        Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .medium))
          .foregroundStyle(ink).frame(width: 44, height: 38)
          .background(amber, in: RoundedRectangle(cornerRadius: 10))
      }.buttonStyle(.plain).accessibilityLabel("Export photograph").accessibilityIdentifier(
        "export"
      )
      .padding(.leading, 4)
    }.padding(.leading, 7).padding(.trailing, 18).frame(height: 52)
  }

  private var photoTitle: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Text(store.photo.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
        Text(store.photo.subtitle).font(.system(size: 8, design: .monospaced))
          .tracking(1.1).foregroundStyle(muted).lineLimit(1)
      }
      Spacer()
      IconButton(
        icon: store.isFavorite ? "star.fill" : "star", label: "Star photograph",
        active: store.isFavorite
      ) { store.toggleFavorite(store.photo.id) }
      .accessibilityIdentifier("favorite")
      Menu {
        Button("Copy color & light", systemImage: "doc.on.doc") { store.copyEdits() }
        Button("Paste color & light", systemImage: "doc.on.clipboard") { store.pasteEdits() }
          .disabled(store.copiedEdit == nil)
        Divider()
        Button("Photograph details", systemImage: "info.circle") { information = true }
        Button("Reset all edits", systemImage: "arrow.counterclockwise", role: .destructive) {
          resetting = true
        }
        .disabled(!store.isEdited)
      } label: {
        Image(systemName: "ellipsis").font(.system(size: 18))
          .frame(width: 32, height: 44).contentShape(Rectangle())
      }.accessibilityLabel("Photograph actions").accessibilityIdentifier("photo-actions")
    }.padding(.leading, 22).padding(.trailing, 16).frame(height: 48)
  }

  private var canvas: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black.opacity(0.6)
        if let image = comparing ? store.comparison : store.preview {
          Image(uiImage: image).resizable().scaledToFit()
            .overlay {
              GeometryReader { imageGeometry in
                if split, let original = store.comparison {
                  Image(uiImage: original).resizable().scaledToFit()
                    .mask(alignment: .leading) {
                      Rectangle().frame(width: imageGeometry.size.width * splitPosition)
                    }
                  Rectangle().fill(.white.opacity(0.9)).frame(width: 1)
                    .offset(x: imageGeometry.size.width * splitPosition)
                  Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(ink)
                    .frame(width: 30, height: 30).background(paper, in: Circle())
                    .position(
                      x: imageGeometry.size.width * splitPosition, y: imageGeometry.size.height / 2)
                  HStack {
                    Text("BEFORE")
                    Spacer()
                    Text("AFTER")
                  }.font(.system(size: 8, weight: .semibold)).tracking(1.2)
                    .padding(10).shadow(color: .black, radius: 3)
                }
                if tool == .crop && !comparing {
                  GridOverlay().stroke(.white.opacity(0.4), lineWidth: 0.5)
                }
              }.allowsHitTesting(false)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .accessibilityLabel(comparing ? "Original color photograph" : "Developed photograph")
        } else if store.previewUnavailable {
          VStack(spacing: 12) {
            Image(systemName: "photo.badge.exclamationmark").font(.system(size: 28, weight: .light))
            Text("Original unavailable").font(.system(size: 18, design: .serif))
            Text("Return to your library to choose another photograph.")
              .font(.system(size: 11)).foregroundStyle(muted)
          }
        } else {
          ProgressView().tint(amber)
        }
        if comparing || tool == .crop {
          VStack {
            Text(comparing ? "ORIGINAL COLOR" : "DRAG TO REFRAME")
              .font(.system(size: 8, weight: .medium)).tracking(1.6)
              .padding(8).background(.black.opacity(0.6), in: Capsule())
            Spacer()
          }.padding(12).allowsHitTesting(false)
        }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 6)
          .onChanged { value in
            if split {
              let imageRatio = store.preview.map { $0.size.width / $0.size.height } ?? 1
              let width = min(proxy.size.width, proxy.size.height * imageRatio)
              let inset = (proxy.size.width - width) / 2
              splitPosition = min(0.95, max(0.05, (value.location.x - inset) / width))
            } else if tool == .crop {
              if panStart == nil { panStart = store.draft }
              guard let start = panStart else { return }
              store.draft.panX = min(1, max(-1, start.panX - value.translation.width / 150))
              store.draft.panY = min(1, max(-1, start.panY + value.translation.height / 150))
              store.render()
            }
          }
          .onEnded { _ in
            if panStart != nil { store.commit() }
            panStart = nil
          }
      )
    }
  }

  private var imageToolbar: some View {
    HStack(spacing: 8) {
      Button {
        showHistogram.toggle()
      } label: {
        if showHistogram {
          HistogramView(histogram: store.histogram).frame(width: 94, height: 24)
        } else {
          Label("Histogram", systemImage: "waveform.path").font(.system(size: 10))
        }
      }.buttonStyle(.plain).frame(width: 104, height: 44).accessibilityLabel("Toggle histogram")
      if showHistogram {
        Text("RGB").font(.system(size: 7, design: .monospaced)).foregroundStyle(muted)
      }
      Spacer(minLength: 0)
      Button {
        split.toggle()
        comparing = false
        if split { tool = .looks }
      } label: {
        Image(systemName: "rectangle.lefthalf.filled").font(.system(size: 15))
          .foregroundStyle(split ? amber : muted).frame(width: 40, height: 44)
      }.buttonStyle(.plain).accessibilityLabel("Split comparison").accessibilityIdentifier(
        "split-compare")
      Text(comparing ? "Original" : "Hold original")
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(comparing ? amber : muted)
        .frame(minWidth: 79, minHeight: 44).contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { _ in comparing = true }
            .onEnded { _ in comparing = false }
        )
        .accessibilityAddTraits(.isButton).accessibilityLabel("Compare original")
        .accessibilityAction { comparing.toggle() }.accessibilityIdentifier("compare")
    }.padding(.horizontal, 19).frame(height: 44)
  }

  private var toolPicker: some View {
    HStack(spacing: 0) {
      ForEach(Tool.allCases, id: \.self) { item in
        Button {
          tool = item
        } label: {
          VStack(spacing: 6) {
            Image(systemName: item.icon).font(.system(size: 16, weight: .light))
            Text(item.rawValue).font(.system(size: 10, weight: .medium))
          }.foregroundStyle(tool == item ? amber : muted)
            .frame(maxWidth: .infinity).frame(height: 52)
            .overlay(alignment: .bottom) {
              Capsule().fill(tool == item ? amber : .clear).frame(width: 18, height: 2)
            }
        }.buttonStyle(.plain).accessibilityIdentifier("tool-\(item.rawValue.lowercased())")
          .accessibilityAddTraits(tool == item ? .isSelected : [])
      }
    }.padding(.horizontal, 12).background(panel)
      .overlay(alignment: .top) { hairline.frame(height: 0.5) }
  }

  @ViewBuilder private var controls: some View {
    switch tool {
    case .looks: lookControls
    case .crop: cropControls
    default: adjustmentControls
    }
  }

  private func binding(_ key: WritableKeyPath<Edit, Double>) -> Binding<Double> {
    Binding(
      get: { store.draft[keyPath: key] },
      set: {
        store.draft[keyPath: key] = $0
        store.render()
      })
  }

  private var lookControls: some View {
    VStack(spacing: 7) {
      ScrollView(.horizontal) {
        HStack(spacing: 10) {
          ForEach(FilmLook.allCases, id: \.self) { look in
            Button {
              store.change { $0.look = look }
            } label: {
              VStack(spacing: 5) {
                Group {
                  if let image = store.thumbnails[look] {
                    Image(uiImage: image).resizable().scaledToFill()
                  } else {
                    panel
                  }
                }.frame(width: 62, height: 66).clipped()
                  .clipShape(RoundedRectangle(cornerRadius: 5))
                  .overlay(
                    RoundedRectangle(cornerRadius: 5)
                      .stroke(store.draft.look == look ? amber : .clear, lineWidth: 1.5)
                  )
                  .overlay(alignment: .bottomTrailing) {
                    if store.draft.look == look {
                      Image(systemName: "checkmark").font(.system(size: 7, weight: .bold))
                        .foregroundStyle(ink).padding(4).background(amber, in: Circle()).padding(4)
                    }
                  }
                Text(look.rawValue).font(.system(size: 9, weight: .medium))
                  .foregroundStyle(store.draft.look == look ? paper : muted)
              }
            }.buttonStyle(.plain).accessibilityLabel("\(look.rawValue) look")
              .accessibilityIdentifier("look-\(look.rawValue.lowercased())")
          }
        }.padding(.horizontal, 22).padding(.top, 2)
      }.scrollIndicators(.hidden)
      HStack(spacing: 14) {
        Text("AMOUNT").font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(
          muted)
        PrecisionSlider(value: binding(\.lookAmount), range: 0...1, onCommit: store.commit)
          .disabled(store.draft.look == .original)
          .opacity(store.draft.look == .original ? 0.3 : 1)
          .accessibilityLabel("Look amount")
        Text("\(Int(store.draft.lookAmount * 100))")
          .font(.system(size: 11, design: .monospaced)).foregroundStyle(amber).frame(width: 24)
      }.padding(.horizontal, 22)
    }
  }

  private var adjustmentControls: some View {
    VStack(spacing: 4) {
      HStack(spacing: 2) {
        ForEach(tool.adjustments, id: \.self) { item in
          Button {
            adjustment = item
          } label: {
            Text(item.rawValue).font(.system(size: 10, weight: .medium))
              .foregroundStyle(item == adjustment ? paper : muted)
              .frame(maxWidth: .infinity).frame(height: 38)
              .background(item == adjustment ? paper.opacity(0.07) : .clear, in: Capsule())
          }.buttonStyle(.plain)
        }
      }
      HStack {
        Text(adjustment.hint).font(.system(size: 10)).foregroundStyle(muted)
        Spacer()
        Button {
          numericText = adjustment.display(store.draft[keyPath: adjustment.key])
          numericEntry = true
        } label: {
          HStack(spacing: 4) {
            Text(adjustment.display(store.draft[keyPath: adjustment.key]))
              .font(.system(size: 17, weight: .light, design: .monospaced))
            Text(adjustment == .exposure ? "EV" : "").font(.system(size: 8))
            Image(systemName: "pencil").font(.system(size: 8))
          }.foregroundStyle(amber).frame(minHeight: 38)
        }.buttonStyle(.plain).accessibilityLabel("Set \(adjustment.rawValue) value")
          .accessibilityIdentifier("numeric-value")
      }
      HStack(spacing: 12) {
        PrecisionSlider(
          value: binding(adjustment.key), range: adjustment.range,
          neutral: adjustment.neutral, onCommit: store.commit
        )
        .accessibilityLabel(adjustment.rawValue)
        .accessibilityValue(adjustment.display(store.draft[keyPath: adjustment.key]))
        .accessibilityIdentifier("tone-slider")
        IconButton(icon: "arrow.counterclockwise", label: "Reset \(adjustment.rawValue)") {
          store.change { $0[keyPath: adjustment.key] = adjustment.neutral }
        }.opacity(store.draft[keyPath: adjustment.key] == adjustment.neutral ? 0.3 : 1)
          .disabled(store.draft[keyPath: adjustment.key] == adjustment.neutral)
      }
    }.padding(.horizontal, 22)
  }

  private var cropControls: some View {
    VStack(spacing: 8) {
      HStack(spacing: 7) {
        ForEach(CropFormat.allCases, id: \.self) { format in
          Button {
            store.change {
              $0.crop = format
              $0.panX = 0
              $0.panY = 0
            }
          } label: {
            VStack(spacing: 5) {
              Image(systemName: format == .square ? "square" : "rectangle")
                .font(.system(size: 16, weight: .ultraLight))
              Text(format.rawValue).font(.system(size: 9, weight: .medium))
            }.frame(maxWidth: .infinity).frame(height: 49)
              .foregroundStyle(store.draft.crop == format ? amber : muted)
              .background(
                store.draft.crop == format ? amber.opacity(0.08) : .clear,
                in: RoundedRectangle(cornerRadius: 8))
          }.buttonStyle(.plain).accessibilityLabel("Crop \(format.rawValue)")
        }
        IconButton(icon: "rotate.right", label: "Rotate clockwise") {
          store.change { $0.rotation = ($0.rotation + 1) % 4 }
        }.accessibilityIdentifier("rotate")
      }
      HStack(spacing: 12) {
        Eyebrow(text: "Zoom")
        PrecisionSlider(value: binding(\.zoom), range: 1...2.5, neutral: 1, onCommit: store.commit)
          .accessibilityLabel("Crop zoom")
        Text(String(format: "%.2f×", store.draft.zoom))
          .font(.system(size: 11, design: .monospaced)).foregroundStyle(amber)
      }
      Text("Composition is reversible. Your original stays intact.")
        .font(.system(size: 9)).foregroundStyle(muted)
    }.padding(.horizontal, 22)
  }

  private var footer: some View {
    HStack(spacing: 6) {
      Circle().fill(store.status == "Not saved" ? .orange : amber.opacity(0.8)).frame(
        width: 4, height: 4)
      Text(store.status).font(.system(size: 9)).foregroundStyle(muted)
      Spacer()
      if store.rendering { ProgressView().scaleEffect(0.5).frame(width: 16, height: 16) }
      Text("sRGB").font(.system(size: 8, design: .monospaced)).foregroundStyle(muted)
      Rectangle().fill(hairline).frame(width: 1, height: 10).padding(.horizontal, 5)
      Text("NONDESTRUCTIVE").font(.system(size: 7, design: .monospaced)).tracking(1)
        .foregroundStyle(muted)
    }.padding(.horizontal, 22).frame(height: 35)
      .overlay(alignment: .top) { hairline.frame(height: 0.5) }
  }

  private var photoInformation: some View {
    NavigationStack {
      List {
        Section("Original") {
          LabeledContent("Title", value: store.photo.title)
          LabeledContent(
            "Source",
            value: store.photo.isImported ? "Imported photograph" : "Original AI-generated study")
          LabeledContent("Dimensions", value: store.photo.dimensions)
          LabeledContent("Storage", value: "On this iPhone")
        }
        Section("Develop") {
          LabeledContent("Look", value: store.draft.look.rawValue)
          LabeledContent("History", value: "\(store.history.undoStack.count) undo steps")
          LabeledContent("Working color", value: "sRGB")
        }
        Section {
          Text(
            "Edits are stored separately from your original. Export creates a new, flattened image."
          )
          .foregroundStyle(.secondary)
        }
      }.navigationTitle("Photograph").navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) { Button("Done") { information = false } }
        }
    }.presentationDetents([.medium, .large])
  }
}

private struct GridOverlay: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.addRect(rect)
      for fraction in [1.0 / 3, 2.0 / 3] {
        path.move(to: CGPoint(x: rect.width * fraction, y: 0))
        path.addLine(to: CGPoint(x: rect.width * fraction, y: rect.height))
        path.move(to: CGPoint(x: 0, y: rect.height * fraction))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * fraction))
      }
    }
  }
}
