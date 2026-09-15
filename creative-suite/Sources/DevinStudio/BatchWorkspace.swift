import SwiftUI
import DevinCore

struct BatchWorkspace: View {
    @ObservedObject var session: StudioSession
    var images: [CanvasElement] { session.document.elements.filter { $0.kind == .image } }
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Goodbye, one at a time.").font(.system(size: 26, weight: .medium)).tracking(-0.7)
                        Text("One queue. A whole folder of possibilities.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text("\(images.count) ASSETS").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.accent)
                }.padding(30)
                if images.isEmpty {
                    EmptyWorkspace(symbol: "square.3.layers.3d", title: "A little less busywork.", description: "Import a group of images. Set a maximum size and export them together as PNG, JPEG, or TIFF. Original files stay untouched.", button: "Add images") { session.importFiles() }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 16)], spacing: 16) {
                            ForEach(images) { image in
                                VStack(alignment: .leading, spacing: 12) {
                                    if let data = image.imageData, let nsImage = NSImage(data: data) {
                                        Image(nsImage: nsImage).resizable().scaledToFit().frame(height: 140).frame(maxWidth: .infinity).background(Theme.background, in: RoundedRectangle(cornerRadius: 5))
                                    }
                                    Text(image.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                    HStack { Text("\(Int(image.width)) × \(Int(image.height))").font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted); Spacer(); Button { session.selectedID = image.id; session.deleteSelection() } label: { Image(systemName: "xmark").font(.system(size: 9)) }.buttonStyle(.plain).help("Remove from queue") }
                                }.padding(13).background(Theme.panel, in: RoundedRectangle(cornerRadius: 9))
                            }
                        }.padding(.horizontal, 30).padding(.bottom, 30)
                    }
                }
            }
            VStack(spacing: 0) {
                InspectorSection(title: "Output settings") {
                    Text("Image conversion").font(.system(size: 15, weight: .medium))
                    Text("Choose the file type, JPEG quality, and maximum edge size in the export dialog.").font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(4)
                    Button { session.showExport = true } label: { Label("Export queue", systemImage: "arrow.up.right") }.buttonStyle(StudioButtonStyle(primary: true)).disabled(images.isEmpty)
                }
                InspectorSection(title: "Safe by default") {
                    Label("No source files changed", systemImage: "checkmark.shield").font(.system(size: 11)).foregroundStyle(Theme.accent)
                    Text("Exports go in a new, uniquely named subfolder. Images keep their aspect ratio and are never enlarged.").font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(4)
                }
                Spacer()
                Button("Add more images") { session.importFiles() }.buttonStyle(StudioButtonStyle()).padding(20)
            }.frame(width: 254).background(Theme.sidebar)
        }
    }
}
