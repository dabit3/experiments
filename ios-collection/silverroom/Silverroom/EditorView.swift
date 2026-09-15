import SwiftUI

enum ToolTab: String, CaseIterable {
  case looks = "Looks"
  case adjust = "Adjust"
  case frame = "Frame"
  case recipes = "Recipes"
}

enum Adjustment: String, CaseIterable {
  case exposure = "Exposure"
  case contrast = "Contrast"
  case warmth = "Warmth"
  var range: ClosedRange<Double> {
    switch self {
    case .exposure: -2...2
    case .contrast: 0.5...1.5
    case .warmth: -1...1
    }
  }
  var neutral: Double { self == .contrast ? 1 : 0 }
  var lowerLabel: String {
    switch self {
    case .exposure: "−2 EV"
    case .contrast: "Softer"
    case .warmth: "Cooler"
    }
  }
  var upperLabel: String {
    switch self {
    case .exposure: "+2 EV"
    case .contrast: "Stronger"
    case .warmth: "Warmer"
    }
  }
}

struct EditorView: View {
  @EnvironmentObject private var library: LibraryStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var typeSize
  @StateObject private var room: Darkroom
  let negative: Negative
  @State private var tab: ToolTab = .looks
  @State private var adjustment: Adjustment = .exposure
  @State private var comparing = false
  @State private var showReset = false
  @State private var showRecipes = false
  @State private var showSave = false
  @State private var exportFile: ExportFile?
  @State private var saved = false
  @ScaledMetric(relativeTo: .caption) private var filmWidth: CGFloat = 52

  init(negative: Negative) {
    self.negative = negative
    _room = StateObject(wrappedValue: Darkroom(settings: negative.settings))
  }

  var body: some View {
    VStack(spacing: 0) {
      toolbar
      if typeSize.isAccessibilitySize {
        ScrollView {
          VStack(spacing: 0) {
            photo(height: 260)
            historyBar
            tools
          }
        }
        .scrollIndicators(.hidden)
      } else {
        GeometryReader { geometry in
          photo(height: geometry.size.height)
        }
        historyBar
        tools
      }
    }
    .background(Palette.canvas)
    .foregroundStyle(Palette.silver)
    .task {
      do { await room.load(data: try library.data(for: negative)) } catch {
        room.error = error.localizedDescription
      }
    }
    .task(id: room.settings) {
      library.update(negative, settings: room.settings)
      saved = false
      await room.develop()
    }
    .sheet(isPresented: $showRecipes) {
      RecipeShelf(negative: negative) { recipe in
        room.apply(recipe)
        showRecipes = false
      }
    }
    .sheet(item: $exportFile) { file in ExportView(file: file) }
    .sheet(isPresented: $showSave) {
      RecipeNameSheet(title: "Save a recipe", initialName: room.settings.film.title) { name in
        library.addRecipe(name: name, settings: room.settings)
        saved = true
      }
    }
    .sheet(isPresented: $showReset) {
      NoticeSheet(
        title: "Reset photograph?",
        detail: "Restore the original look and framing. You can undo this. Saved recipes are kept.",
        actionTitle: "Reset all edits"
      ) {
        room.edit { $0 = EditSettings() }
        comparing = false
      }
    }
    .sheet(
      isPresented: Binding(
        get: { room.error != nil || library.error != nil },
        set: {
          if !$0 {
            room.error = nil
            library.error = nil
          }
        })
    ) {
      NoticeSheet(
        title: "Couldn’t complete that", detail: room.error ?? library.error ?? "",
        actionTitle: "Dismiss"
      ) {
        room.error = nil
        library.error = nil
      }
    }
    .sensoryFeedback(.selection, trigger: room.settings.film)
    .sensoryFeedback(.selection, trigger: tab)
    .sensoryFeedback(.success, trigger: saved)
  }

  private var toolbar: some View {
    HStack(spacing: 10) {
      RoundControl(symbol: "chevron.left", label: "Back to library") { dismiss() }
      VStack(alignment: .leading, spacing: 3) {
        Text(negative.title).font(TypeStyle.heading)
        if room.outputSize != .zero {
          Text("\(Int(room.outputSize.width)) × \(Int(room.outputSize.height))")
            .font(TypeStyle.caption).foregroundStyle(Palette.muted).monospacedDigit()
        }
      }
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        Task {
          let directory = library.disk.directory.appendingPathComponent(
            "Exports", isDirectory: true)
          if let url = await room.export(directory: directory) { exportFile = ExportFile(url: url) }
        }
      } label: {
        HStack(spacing: 7) {
          if room.exporting { ProgressView().tint(Palette.background) }
          Text(room.exporting ? "Exporting" : "Export").font(TypeStyle.label)
        }
        .padding(.horizontal, 16).frame(minHeight: 44)
        .foregroundStyle(Palette.background)
        .background(Palette.silver, in: Capsule())
      }
      .disabled(room.preview == nil || room.exporting)
      .opacity(room.preview == nil ? 0.4 : 1)
      .accessibilityLabel(room.exporting ? "Exporting" : "Export photograph")
    }
    .padding(.leading, 8).padding(.trailing, 20).padding(.vertical, 8)
  }

  private func photo(height: CGFloat) -> some View {
    ZStack {
      Palette.canvas
      if let image = comparing ? room.original : room.preview {
        Image(uiImage: image).resizable().scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityLabel(
            comparing
              ? "Original photograph" : "Edited photograph, \(room.settings.film.title) look")
      } else {
        ProgressView("Opening photograph").font(TypeStyle.label).tint(Palette.silver)
      }
    }
    .frame(height: max(1, height - 16))
    .padding(.horizontal, 12).padding(.vertical, 8)
    .contentShape(Rectangle())
    .onLongPressGesture(minimumDuration: 0.12, pressing: { comparing = $0 }, perform: {})
  }

  private var historyBar: some View {
    HStack(spacing: 0) {
      RoundControl(symbol: "arrow.uturn.backward", label: "Undo edit") { room.undo() }
        .disabled(!room.canUndo)
      RoundControl(symbol: "arrow.uturn.forward", label: "Redo edit") { room.redo() }
        .disabled(!room.canRedo)
      Spacer(minLength: 0)
      Text(comparing ? "Original" : "Hold to compare")
        .font(TypeStyle.caption)
        .foregroundStyle(comparing ? Palette.silver : Palette.muted)
        .frame(minHeight: 44).contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.01, pressing: { comparing = $0 }, perform: {})
        .accessibilityLabel("Compare with original")
        .accessibilityValue(comparing ? "Showing original" : "Showing edited photograph")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { comparing.toggle() }
      Spacer(minLength: 0)
      RoundControl(symbol: "arrow.counterclockwise", label: "Reset edits") { showReset = true }
        .disabled(room.settings == EditSettings())
    }
    .padding(.horizontal, 12)
  }

  private var tools: some View {
    VStack(spacing: 0) {
      Hairline()
      Group {
        switch tab {
        case .looks: filmstrip
        case .adjust: adjustmentPanel
        case .frame: framePanel
        case .recipes: recipePanel
        }
      }
      .frame(height: typeSize.isAccessibilitySize ? nil : 218)
      .padding(.vertical, typeSize.isAccessibilitySize ? 14 : 0)
      ViewThatFits(in: .horizontal) {
        tabButtons
        ScrollView(.horizontal, showsIndicators: false) { tabButtons }
      }
      .padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 8)
    }
    .background(Palette.background.ignoresSafeArea(edges: .bottom))
  }

  private var tabButtons: some View {
    HStack(spacing: 4) {
      ForEach(ToolTab.allCases, id: \.self) { item in
        Button {
          withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) { tab = item }
        } label: {
          Text(item.rawValue).font(TypeStyle.label)
            .fixedSize().frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 10)
            .foregroundStyle(tab == item ? Palette.silver : Palette.muted)
            .background(
              tab == item ? Palette.panel : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain).accessibilityAddTraits(tab == item ? .isSelected : [])
      }
    }
  }

  private var filmstrip: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .firstTextBaseline) {
        Text("Film looks").font(TypeStyle.label)
        Spacer()
        Text(room.settings.film.title).font(TypeStyle.caption).foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 20)
      ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(Film.allCases) { film in
              Button {
                room.edit { $0.film = film }
              } label: {
                VStack(spacing: 8) {
                  Group {
                    if let image = room.films[film] {
                      Image(uiImage: image).resizable().scaledToFill()
                    } else {
                      Palette.panel
                    }
                  }
                  .frame(width: filmWidth, height: filmWidth * 1.35).clipped()
                  .clipShape(RoundedRectangle(cornerRadius: 5)).padding(3)
                  .overlay {
                    RoundedRectangle(cornerRadius: 8)
                      .strokeBorder(
                        room.settings.film == film ? Palette.silver : .clear, lineWidth: 1.5)
                  }
                  Text(film.title).font(TypeStyle.caption)
                    .foregroundStyle(room.settings.film == film ? Palette.silver : Palette.muted)
                }
              }
              .buttonStyle(.plain).id(film)
              .accessibilityLabel("\(film.title) look")
              .accessibilityAddTraits(room.settings.film == film ? .isSelected : [])
            }
          }
          .padding(.horizontal, 17)
        }
        .onChange(of: room.settings.film) { _, film in
          withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            proxy.scrollTo(film, anchor: .center)
          }
        }
        .onAppear { proxy.scrollTo(room.settings.film, anchor: .center) }
      }
      Text(filmDescription).font(TypeStyle.caption).foregroundStyle(Palette.muted)
        .padding(.horizontal, 20)
    }
  }

  private var filmDescription: String {
    switch room.settings.film {
    case .original: "Unfiltered color"
    case .silver: "Soft monochrome · luminous midtones"
    case .noir: "Deep monochrome · rich shadows"
    case .dune: "Warm color · gentle contrast"
    case .faded: "Muted color · lifted blacks"
    }
  }

  private var adjustmentPanel: some View {
    VStack(spacing: 12) {
      ViewThatFits(in: .horizontal) {
        adjustmentButtons
        ScrollView(.horizontal, showsIndicators: false) { adjustmentButtons }
      }
      HStack(alignment: .firstTextBaseline) {
        Text(valueText).font(TypeStyle.value).monospacedDigit()
          .foregroundStyle(
            adjustmentBinding.wrappedValue == adjustment.neutral ? Palette.silver : Palette.amber)
        Spacer()
        Button("Reset value") { adjustmentBinding.wrappedValue = adjustment.neutral }
          .font(TypeStyle.caption).foregroundStyle(Palette.muted).frame(minHeight: 44)
          .disabled(adjustmentBinding.wrappedValue == adjustment.neutral)
          .accessibilityLabel("Reset \(adjustment.rawValue.lowercased()) to neutral")
      }
      VStack(spacing: 3) {
        Slider(
          value: adjustmentBinding, in: adjustment.range, step: 0.05,
          onEditingChanged: room.setAdjusting
        )
        .tint(Palette.silver)
        .accessibilityLabel(adjustment.rawValue).accessibilityValue(valueText)
        HStack {
          ForEach(0..<21) { index in
            Rectangle().fill(index == 10 ? Palette.silver : Palette.muted.opacity(0.45))
              .frame(width: 1, height: index.isMultiple(of: 5) ? 9 : 4)
            if index < 20 { Spacer(minLength: 0) }
          }
        }
        .padding(.horizontal, 3).accessibilityHidden(true)
      }
      HStack {
        Text(adjustment.lowerLabel)
        Spacer()
        Text(adjustment == .contrast ? "1.00" : "0")
        Spacer()
        Text(adjustment.upperLabel)
      }
      .font(TypeStyle.caption).foregroundStyle(Palette.muted)
    }
    .padding(.horizontal, 24)
  }

  private var adjustmentButtons: some View {
    HStack(spacing: 14) {
      ForEach(Adjustment.allCases, id: \.self) { item in
        Button {
          adjustment = item
        } label: {
          VStack(spacing: 5) {
            Text(item.rawValue).font(TypeStyle.label).fixedSize()
            Circle().fill(adjustment == item ? Palette.silver : .clear).frame(width: 3, height: 3)
          }
          .foregroundStyle(adjustment == item ? Palette.silver : Palette.muted)
          .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityAddTraits(adjustment == item ? .isSelected : [])
      }
    }
  }

  private var adjustmentBinding: Binding<Double> {
    Binding(
      get: {
        switch adjustment {
        case .exposure: room.settings.exposure
        case .contrast: room.settings.contrast
        case .warmth: room.settings.warmth
        }
      },
      set: { value in
        room.edit {
          switch adjustment {
          case .exposure: $0.exposure = value
          case .contrast: $0.contrast = value
          case .warmth: $0.warmth = value
          }
        }
      })
  }

  private var valueText: String {
    switch adjustment {
    case .exposure: String(format: "%+.2f EV", room.settings.exposure)
    case .contrast: String(format: "%.2f×", room.settings.contrast)
    case .warmth: String(format: "%+.0f", room.settings.warmth * 100)
    }
  }

  private var framePanel: some View {
    VStack(spacing: 16) {
      HStack(spacing: 14) {
        ratioButton(square: false)
        ratioButton(square: true)
      }
      HStack {
        Text("\(room.settings.quarterTurns * 90)° rotation")
          .font(TypeStyle.caption).foregroundStyle(Palette.muted)
        Spacer()
        Button {
          room.edit { $0.quarterTurns += 1 }
        } label: {
          Label("Rotate", systemImage: "rotate.right").font(TypeStyle.label).frame(minHeight: 44)
        }
        .accessibilityLabel("Rotate 90 degrees")
      }
      Text(
        room.settings.squareCrop
          ? "Square crop is centered on the photograph." : "The full photograph is preserved."
      )
      .font(TypeStyle.caption).foregroundStyle(Palette.muted)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 24)
  }

  private func ratioButton(square: Bool) -> some View {
    let selected = room.settings.squareCrop == square
    return Button {
      room.edit { $0.squareCrop = square }
    } label: {
      VStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 2).stroke(lineWidth: 1.2)
          .frame(width: square ? 24 : 34, height: 24).frame(height: 28)
        Text(square ? "Square" : "Original").font(TypeStyle.label)
      }
      .foregroundStyle(selected ? Palette.silver : Palette.muted)
      .frame(maxWidth: .infinity).padding(.vertical, 14)
      .background(selected ? Palette.panel : .clear, in: RoundedRectangle(cornerRadius: 10))
    }
    .accessibilityLabel(square ? "Square crop" : "Original ratio")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var recipePanel: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(saved ? "Recipe saved" : "Keep this look").font(TypeStyle.heading)
        Spacer()
        if saved { Image(systemName: "checkmark").foregroundStyle(Palette.amber) }
      }
      Text("Use these adjustments on another photograph.")
        .font(TypeStyle.label).foregroundStyle(Palette.muted)
      Button {
        showSave = true
      } label: {
        Text("Save recipe").frame(maxWidth: .infinity)
      }
      .buttonStyle(PrimaryButton())
      Button {
        showRecipes = true
      } label: {
        HStack {
          Text("Saved recipes")
          Spacer()
          Text("\(library.state.recipes.count)").foregroundStyle(Palette.muted)
          Image(systemName: "chevron.right").font(TypeStyle.caption)
        }
        .font(TypeStyle.label).frame(minHeight: 44)
      }
    }
    .padding(.horizontal, 24)
  }
}
