import SwiftUI
import DevinCore

struct FormWorkspace: View {
    @ObservedObject var session: StudioSession
    @State private var panel = "Properties"
    @State private var showSwatches = false
    var body: some View {
        VStack(spacing: 0) {
            ProAppBar(session: session)
            controlBar
            HStack(spacing: 0) {
                if !session.panelsHidden { ProToolRail(session: session, twoColumns: true) }
                VStack(spacing: 0) { ProDocumentTab(session: session); ProCanvasViewport(session: session); ProStatusBar(session: session) }
                if !session.panelsHidden {
                    VStack(spacing: 12) {
                        ProIcon(symbol: "paintpalette", help: "Color and Swatches", active: showSwatches) { showSwatches.toggle() }
                        ProIcon(symbol: "slider.horizontal.3", help: "Properties", active: panel == "Properties") { panel = "Properties" }
                        ProIcon(symbol: "square.3.layers.3d", help: "Layers", active: panel == "Layers") { panel = "Layers" }
                        ProIcon(symbol: "rectangle.stack", help: "Artboards", active: panel == "Artboards") { panel = "Artboards" }
                        Spacer()
                    }.padding(.top, 9).frame(width: 37).background(ProTheme.header)
                    VStack(spacing: 0) {
                        ProTabs(tabs: ["Properties", "Layers", "Artboards"], selected: $panel)
                        if showSwatches { ProColorPanel(session: session).frame(height: 220) }
                        switch panel {
                        case "Layers": ProLayerPanel(session: session)
                        case "Artboards": artboards
                        default: ProPropertiesPanel(session: session)
                        }
                    }.frame(width: 285).background(ProTheme.panel)
                }
            }
        }.background(ProTheme.background).foregroundStyle(ProTheme.text)
    }
    var controlBar: some View {
        HStack(spacing: 12) {
            Text(session.selected.map { $0.kind.rawValue.capitalized } ?? "No Selection").font(.system(size: 10)).frame(width: 85, alignment: .leading)
            Divider().frame(height: 22)
            ProColorControl("Fill", selection: session.elementColor(\.fill), supportsOpacity: false).labelsHidden().frame(width: 30)
            ProColorControl("Stroke", selection: session.elementColor(\.stroke), supportsOpacity: false).labelsHidden().frame(width: 30)
            ProField(label: "Stroke", value: session.elementBinding(\.strokeWidth, 0), range: 0...200, suffix: "pt").frame(width: 116)
            ProField(label: "Opacity", value: Binding(get: { (session.selected?.opacity ?? 1) * 100 }, set: { value in session.updateElement { $0.opacity = value / 100 } }), range: 0...100, suffix: "%").frame(width: 122)
            Divider().frame(height: 22)
            ProField(label: "X", value: session.elementBinding(\.x, 0)).frame(width: 95)
            ProField(label: "Y", value: session.elementBinding(\.y, 0)).frame(width: 95)
            Spacer()
            Button("Document Setup") { session.select(nil); panel = "Properties" }.buttonStyle(ProButtonStyle())
            Button("Export") { session.showExport = true }.buttonStyle(ProButtonStyle())
        }.padding(.horizontal, 12).frame(height: 40).background(ProTheme.panel).overlay(alignment: .bottom) { Rectangle().fill(ProTheme.border).frame(height: 1) }
    }
    var artboards: some View {
        VStack(spacing: 0) {
            List {
                ForEach(0..<session.document.pageCount, id: \.self) { page in
                    HStack { Image(systemName: "rectangle"); Text(String(format: "%02d", page + 1)); Text("Artboard \(page + 1)"); Spacer() }.font(.system(size: 11)).padding(6)
                        .background(session.page == page ? Color(hex: "505050") : .clear).contentShape(Rectangle()).onTapGesture { session.page = page; session.select(nil) }
                }
            }.scrollContentBackground(.hidden).listStyle(.plain)
            HStack { ProIcon(symbol: "plus.square", help: "New artboard") { session.addPage() }; ProIcon(symbol: "square.on.square", help: "Duplicate artboard") { session.addPage(duplicate: true) }; Spacer(); ProIcon(symbol: "trash", help: "Delete artboard") { session.deletePage() }.disabled(session.document.pageCount <= 1) }.padding(8)
        }
    }
}
