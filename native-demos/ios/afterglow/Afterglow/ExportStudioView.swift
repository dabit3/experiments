import SwiftUI

struct ExportStudioView: View {
  @ObservedObject var store: EditorStore
  @Environment(\.dismiss) private var dismiss
  @AppStorage("exportFormat") private var format: OutputFormat = .jpeg
  @AppStorage("exportSize") private var size: OutputSize = .original
  @AppStorage("exportQuality") private var quality = 0.95

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        HStack {
          Eyebrow(text: store.exported == nil ? "Output studio" : "Export complete")
          Spacer()
          IconButton(icon: "xmark", label: "Close export") { dismiss() }
        }
        Text(store.exported == nil ? "Made to be seen." : "Your light, delivered.")
          .font(.system(size: 33, design: .serif)).tracking(-1)
        if let image = store.exported?.image ?? store.preview {
          Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity)
            .frame(height: store.exported == nil ? 205 : 300)
            .padding(12).background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        }
        if let export = store.exported {
          completed(export)
        } else {
          settings
          Button {
            store.export(format: format, size: size, quality: quality)
          } label: {
            HStack {
              if store.exporting { ProgressView().tint(ink) }
              Text(store.exporting ? "Developing your photograph…" : "Export photograph")
              if !store.exporting { Image(systemName: "arrow.up.right") }
            }
          }.buttonStyle(StudioButton(prominent: true)).disabled(store.exporting)
            .accessibilityIdentifier("confirm-export")
          Text("A new file. Your original and editable settings stay untouched.")
            .font(.system(size: 11)).foregroundStyle(muted).frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
      }.padding(.horizontal, 25).padding(.bottom, 30)
    }
    .background(ink).foregroundStyle(paper).tint(amber)
    .presentationDragIndicator(.visible)
    .interactiveDismissDisabled(store.exporting)
    .alert(
      "Export notice",
      isPresented: Binding(
        get: { store.error != nil }, set: { if !$0 { store.error = nil } })
    ) {
      Button("Continue", role: .cancel) { store.error = nil }
    } message: {
      Text(store.error ?? "")
    }
  }

  private var settings: some View {
    VStack(spacing: 17) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("File format").font(.system(size: 13, weight: .medium))
          Text(format == .jpeg ? "Compact, ready to share" : "Lossless image quality")
            .font(.system(size: 10)).foregroundStyle(muted)
        }
        Spacer()
        Picker("File format", selection: $format) {
          ForEach(OutputFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).frame(width: 145)
      }
      hairline.frame(height: 1)
      HStack {
        Text("Image size").font(.system(size: 13, weight: .medium))
        Spacer()
        Picker("Image size", selection: $size) {
          ForEach(OutputSize.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.tint(amber).font(.system(size: 12))
      }
      if format == .jpeg {
        hairline.frame(height: 1)
        HStack(spacing: 15) {
          Text("Quality").font(.system(size: 13, weight: .medium))
          PrecisionSlider(value: $quality, range: 0.5...1, onCommit: {})
            .accessibilityLabel("JPEG quality")
          Text("\(Int(quality * 100))%").font(.system(size: 12, design: .monospaced))
            .foregroundStyle(amber)
        }
      }
      HStack {
        Text("sRGB").font(.system(size: 10, design: .monospaced))
        Spacer()
        Text("No upscaling · Capture metadata omitted").font(.system(size: 9))
      }.foregroundStyle(muted)
    }.padding(17).background(panel, in: RoundedRectangle(cornerRadius: 12))
      .disabled(store.exporting)
  }

  private func completed(_ export: ExportedPhoto) -> some View {
    VStack(spacing: 18) {
      HStack(spacing: 10) {
        Image(systemName: "checkmark.circle").foregroundStyle(amber).font(
          .system(size: 25, weight: .light))
        VStack(alignment: .leading, spacing: 5) {
          Text("Developed & saved").font(.system(size: 15, weight: .medium))
          Text(
            "\(export.format.rawValue)  ·  \(export.width) × \(export.height)  ·  "
              + ByteCountFormatter.string(fromByteCount: Int64(export.bytes), countStyle: .file)
          )
          .font(.system(size: 10, design: .monospaced)).foregroundStyle(muted)
        }
        Spacer()
      }
      ShareLink(
        item: export.url, preview: SharePreview("Afterglow", image: Image(uiImage: export.image))
      ) {
        Label("Share or save to Files", systemImage: "square.and.arrow.up")
      }.buttonStyle(StudioButton(prominent: true)).accessibilityIdentifier("share-export")
      Button("Export another version") { store.exported = nil }.buttonStyle(StudioButton())
      Text("Saved in Afterglow / Exports. Share a copy anywhere you like.")
        .font(.system(size: 11)).foregroundStyle(muted).multilineTextAlignment(.center)
    }.frame(maxWidth: .infinity)
  }
}
