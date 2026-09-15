import SwiftUI
import DevinCore

struct PressWorkspace: View {
    @ObservedObject var session: StudioSession
    @State private var upperTab = "Pages"
    @State private var lowerTab = "Properties"
    private var facing: Bool { session.document.pageSettings?.facingPages ?? true }
    var body: some View {
        VStack(spacing: 0) {
            ProAppBar(session: session)
            controlBar
            HStack(spacing: 0) {
                if !session.panelsHidden { ProToolRail(session: session) }
                VStack(spacing: 0) { ProDocumentTab(session: session); ProCanvasViewport(session: session, spread: facing); ProStatusBar(session: session) }
                if !session.panelsHidden {
                    VSplitView {
                        VStack(spacing: 0) {
                            ProTabs(tabs: ["Pages", "Layers"], selected: $upperTab)
                            if upperTab == "Pages" { pagesPanel } else { ProLayerPanel(session: session) }
                        }.frame(minHeight: 210, idealHeight: 320)
                        VStack(spacing: 0) {
                            ProTabs(tabs: ["Properties", "Paragraph Styles"], selected: $lowerTab)
                            if lowerTab == "Properties" { ProPropertiesPanel(session: session) } else { paragraphStyles }
                        }.frame(minHeight: 260, idealHeight: 430)
                    }.frame(width: 280).background(ProTheme.panel)
                }
            }
        }.background(ProTheme.background).foregroundStyle(ProTheme.text)
    }
    var controlBar: some View {
        HStack(spacing: 13) {
            VStack(spacing: 5) { Text("A").font(.system(size: 17, weight: .medium)); Text("¶").font(.system(size: 16)) }.foregroundStyle(ProTheme.secondary).frame(width: 20)
            VStack(spacing: 5) {
                Picker("Font", selection: session.elementBinding(\.fontName, "HelveticaNeue")) { ForEach(["HelveticaNeue", "HelveticaNeue-Bold", "Georgia", "Georgia-Bold", "Didot", "AvenirNext-DemiBold"], id: \.self) { Text($0).tag($0) } }.labelsHidden().controlSize(.small)
                HStack { ProField(label: "T", value: session.elementBinding(\.fontSize, 24), range: 1...1000, suffix: "pt"); ProField(label: "↻", value: session.elementBinding(\.rotation, 0), range: -360...360, suffix: "°") }
            }.frame(width: 235)
            Divider().frame(height: 48)
            VStack(spacing: 5) {
                HStack { ProField(label: "X", value: session.elementBinding(\.x, 0)); ProField(label: "W", value: session.elementBinding(\.width, 100), range: 1...16384) }
                HStack { ProField(label: "Y", value: session.elementBinding(\.y, 0)); ProField(label: "H", value: session.elementBinding(\.height, 100), range: 1...16384) }
            }.frame(width: 210)
            Divider().frame(height: 48)
            VStack(spacing: 6) {
                ProColorControl("Fill", selection: session.elementColor(\.fill), supportsOpacity: false).font(.system(size: 10))
                ProColorControl("Stroke", selection: session.elementColor(\.stroke), supportsOpacity: false).font(.system(size: 10))
            }.frame(width: 84)
            Divider().frame(height: 48)
            VStack(alignment: .leading, spacing: 8) {
                ProCheck(title: "Facing Pages", value: Binding(get: { facing }, set: { value in session.mutate { var settings = $0.pageSettings ?? PageSettings(); settings.facingPages = value; $0.pageSettings = settings } }))
                ProCheck(title: "Show Guides", value: $session.showGuides)
            }
            Spacer(minLength: 5)
            Button("Place…") { session.importFiles() }.buttonStyle(ProButtonStyle())
            Button("Export PDF") { session.showExport = true }.buttonStyle(ProButtonStyle())
        }.padding(.horizontal, 10).frame(height: 65).background(ProTheme.panel)
    }
    var pagesPanel: some View {
        VStack(spacing: 0) {
            HStack { Text("Document pages"); Spacer(); Text("\(session.document.pageCount)") }.font(.system(size: 10)).foregroundStyle(ProTheme.secondary).padding(10)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                    ForEach(0..<session.document.pageCount, id: \.self) { page in
                        VStack(spacing: 5) {
                            if let image = Renderer.thumbnail(session.document, page: page) { Image(nsImage: image).resizable().scaledToFit().frame(width: 65, height: 86).background(.white).overlay(Rectangle().stroke(session.page == page ? ProTheme.blue : .black, lineWidth: session.page == page ? 2 : 0.5)) }
                            Text("\(page + 1)").font(.system(size: 10)).foregroundStyle(session.page == page ? ProTheme.blue : ProTheme.text)
                        }.contentShape(Rectangle()).onTapGesture { session.page = page; session.select(nil) }
                    }
                }.padding(12)
            }
            HStack { Text("\(session.document.pageCount) Pages").font(.system(size: 10)); Spacer(); ProIcon(symbol: "plus.square", help: "New page") { session.addPage() }; ProIcon(symbol: "square.on.square", help: "Duplicate page") { session.addPage(duplicate: true) }; ProIcon(symbol: "trash", help: "Delete page") { session.deletePage() }.disabled(session.document.pageCount <= 1) }.padding(.horizontal, 9).frame(height: 29).background(ProTheme.header)
            ProSection(title: "Margins and Columns") {
                HStack { ProField(label: "Margin", value: pageSetting(\.margin, fallback: 36), range: 0...500, suffix: "pt"); ProField(label: "Gutter", value: pageSetting(\.gutter, fallback: 18), range: 0...500, suffix: "pt") }
                Stepper("Columns: \(session.document.pageSettings?.columns ?? 1)", value: Binding(get: { session.document.pageSettings?.columns ?? 1 }, set: { value in session.mutate { var settings = $0.pageSettings ?? PageSettings(); settings.columns = value; $0.pageSettings = settings } }), in: 1...12).font(.system(size: 10)).controlSize(.small)
            }
        }
    }
    var paragraphStyles: some View {
        VStack(spacing: 1) {
            ForEach(["[Basic Paragraph]", "Body", "Heading 1", "Heading 2", "Caption"], id: \.self) { style in
                Button {
                    session.updateElement { e in
                        e.typography = Typography(leading: 1.35)
                        switch style {
                        case "Heading 1": e.fontName = "HelveticaNeue-Bold"; e.fontSize = 64
                        case "Heading 2": e.fontName = "HelveticaNeue-Bold"; e.fontSize = 32
                        case "Caption": e.fontName = "HelveticaNeue"; e.fontSize = 11
                        default: e.fontName = "Georgia"; e.fontSize = 16
                        }
                    }
                } label: { HStack { Text("¶").foregroundStyle(ProTheme.secondary); Text(style); Spacer() }.font(.system(size: 11)).padding(9).contentShape(Rectangle()) }.buttonStyle(.plain).disabled(session.selected?.kind != .text)
            }
            Spacer()
            Text("Select a text frame to apply a style preset.").font(.system(size: 10)).foregroundStyle(ProTheme.secondary).padding(12)
        }
    }
    func pageSetting(_ key: WritableKeyPath<PageSettings, Double>, fallback: Double) -> Binding<Double> {
        Binding(get: { session.document.pageSettings?[keyPath: key] ?? fallback }, set: { value in session.mutate { var settings = $0.pageSettings ?? PageSettings(); settings[keyPath: key] = value; $0.pageSettings = settings } })
    }
}
