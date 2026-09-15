import SwiftUI
import UIKit

struct ExportFile: Identifiable {
  let id = UUID()
  let url: URL
}

struct ExportView: View {
  @Environment(\.dismiss) private var dismiss
  let file: ExportFile
  @State private var preview: UIImage?
  @State private var dimensions: CGSize = .zero
  @State private var fileSize = ""
  @State private var showShare = false
  @State private var error: String?

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: "Export photograph") { dismiss() }
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Ready to share.").font(TypeStyle.title).padding(.top, 12)
          if let preview {
            Image(uiImage: preview).resizable().scaledToFit()
              .frame(maxWidth: .infinity).frame(maxHeight: 330)
              .accessibilityLabel("Your exported photograph")
          } else if let error {
            Text(error).font(TypeStyle.body).foregroundStyle(Palette.muted)
          } else {
            ProgressView("Preparing preview").font(TypeStyle.label)
              .frame(maxWidth: .infinity, minHeight: 240)
          }
          VStack(spacing: 16) {
            metadata(
              "Dimensions",
              dimensions == .zero ? "—" : "\(Int(dimensions.width)) × \(Int(dimensions.height))")
            metadata("Format", "JPEG · sRGB")
            metadata("File size", fileSize.isEmpty ? "—" : fileSize)
          }
          Hairline()
          Text("Full resolution. Original preserved.")
            .font(TypeStyle.label).foregroundStyle(Palette.muted)
        }
        .padding(24)
      }
      Button {
        showShare = true
      } label: {
        Label("Save or share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
      }
      .buttonStyle(PrimaryButton())
      .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)
    }
    .foregroundStyle(Palette.silver).background(Palette.background)
    .presentationDragIndicator(.visible)
    .sheet(isPresented: $showShare) { ShareSheet(url: file.url) }
    .task {
      let url = file.url
      do {
        let result = try await Task.detached(priority: .userInitiated) {
          let data = try Data(contentsOf: url)
          let engine = ImageEngine()
          return (
            try engine.render(data, settings: EditSettings(), maxPixel: 1000),
            try engine.dimensions(data, settings: EditSettings()),
            ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
          )
        }.value
        preview = result.0
        dimensions = result.1
        fileSize = result.2
      } catch { self.error = error.localizedDescription }
    }
  }

  private func metadata(_ title: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      Text(title).foregroundStyle(Palette.muted)
      Spacer()
      Text(value).multilineTextAlignment(.trailing).monospacedDigit()
    }
    .font(TypeStyle.label)
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let url: URL
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [url], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
