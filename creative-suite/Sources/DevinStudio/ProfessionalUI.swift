import SwiftUI
import AppKit
import DevinCore

enum ProTheme {
    static let background = Color(hex: "232323")
    static let panel = Color(hex: "323232")
    static let header = Color(hex: "292929")
    static let field = Color(hex: "242424")
    static let border = Color(hex: "1C1C1C")
    static let text = Color(hex: "D8D8D8")
    static let secondary = Color(hex: "A5A5A5")
    static let blue = Color(hex: "5BA9F5")
}

struct ProButtonStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11)).foregroundStyle(prominent ? .white : ProTheme.text)
            .padding(.horizontal, 10).frame(height: 24)
            .background(prominent ? Color(hex: "1473E6") : Color(hex: configuration.isPressed ? "282828" : "414141"), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct ProIcon: View {
    let symbol: String
    let help: String
    var active = false
    var size: CGFloat = 26
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 12, weight: .regular)).foregroundStyle(active ? .white : ProTheme.text)
                .frame(width: size, height: size).background(active ? Color(hex: "555555") : .clear, in: RoundedRectangle(cornerRadius: 2))
        }.buttonStyle(.plain).help(help).accessibilityLabel(help)
    }
}

struct ProTabs: View {
    let tabs: [String]
    @Binding var selected: String
    var accent = false
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button { selected = tab } label: {
                    Text(tab).font(.system(size: 11, weight: selected == tab ? .medium : .regular)).lineLimit(1)
                        .foregroundStyle(selected == tab ? (accent ? ProTheme.blue : ProTheme.text) : ProTheme.secondary)
                        .padding(.horizontal, 11).frame(height: 29)
                        .background(selected == tab ? ProTheme.panel : ProTheme.header)
                        .overlay(alignment: .bottom) { if accent && selected == tab { Rectangle().fill(ProTheme.blue).frame(height: 2).padding(.horizontal, 9) } }
                }.buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }.frame(height: 29).background(ProTheme.header).overlay(alignment: .bottom) { Rectangle().fill(ProTheme.border).frame(height: 1) }
    }
}

struct ProSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @State private var expanded = true
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { expanded.toggle() } label: {
                HStack(spacing: 6) { Image(systemName: expanded ? "chevron.down" : "chevron.right").font(.system(size: 8, weight: .semibold)); Text(title).font(.system(size: 11, weight: .semibold)); Spacer() }.foregroundStyle(ProTheme.text)
            }.buttonStyle(.plain)
            if expanded { content }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.3)).frame(height: 1) }
    }
}

struct ProField: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = -10000...10000
    var suffix = ""
    var body: some View {
        HStack(spacing: 5) {
            if !label.isEmpty { Text(label).font(.system(size: 10)).foregroundStyle(ProTheme.secondary).fixedSize() }
            HStack(spacing: 1) {
                TextField(label, value: Binding(get: { value }, set: { if $0.isFinite { value = min(range.upperBound, max(range.lowerBound, $0)) } }), format: .number.precision(.fractionLength(0...2)))
                    .textFieldStyle(.plain).multilineTextAlignment(.trailing).font(.system(size: 11))
                if !suffix.isEmpty { Text(suffix).font(.system(size: 10)).foregroundStyle(ProTheme.secondary) }
            }.padding(.horizontal, 6).frame(height: 22).background(ProTheme.field, in: RoundedRectangle(cornerRadius: 2))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}

struct ProCheck: View {
    let title: String
    @Binding var value: Bool
    var body: some View {
        Button { value.toggle() } label: {
            HStack(spacing: 5) {
                ZStack { Rectangle().fill(ProTheme.field).frame(width: 11, height: 11).overlay(Rectangle().stroke(Color.gray, lineWidth: 0.5)); if value { Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)) } }
                Text(title).font(.system(size: 10)).fixedSize()
            }.foregroundStyle(ProTheme.text)
        }.buttonStyle(.plain)
    }
}

struct ProSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var body: some View {
        VStack(spacing: 6) {
            HStack { Text(title).font(.system(size: 10)).foregroundStyle(ProTheme.secondary); Spacer(); Text(value, format: .number.precision(.fractionLength(0...2))).font(.system(size: 10)).foregroundStyle(ProTheme.blue) }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: "626262")).frame(height: 2)
                    Circle().fill(Color(hex: "BEBEBE")).frame(width: 8, height: 8).offset(x: max(0, min(geo.size.width - 8, (value - range.lowerBound) / (range.upperBound - range.lowerBound) * (geo.size.width - 8))))
                }.frame(height: 12).contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { event in
                    value = range.lowerBound + min(1, max(0, event.location.x / max(1, geo.size.width))) * (range.upperBound - range.lowerBound)
                })
            }.frame(height: 12)
        }
    }
}

struct ProAppBar: View {
    @ObservedObject var session: StudioSession
    var body: some View {
        HStack(spacing: 14) {
            Text(session.tool.name).font(.system(size: 11, weight: .medium)).foregroundStyle(ProTheme.secondary)
            Spacer()
            Text(session.document.title + (session.isDirty ? " *" : "")).font(.system(size: 11)).foregroundStyle(ProTheme.text).lineLimit(1)
            Spacer()
            if session.tool == .cut {
                Button("Import") { session.importFiles() }.buttonStyle(.plain)
                Text("Edit").foregroundStyle(ProTheme.blue)
                Button("Export") { session.showExport = true }.buttonStyle(.plain)
            }
            Menu {
                ForEach(session.tool == .motion ? ["Default", "Animation"] : session.tool == .cut ? ["Editing", "Assembly"] : ["Essentials", "Properties"], id: \.self) { preset in Button(preset) { session.workspacePreset = preset; session.panelsHidden = false } }
                Divider()
                Button("Reset workspace") { session.panelsHidden = false; session.zoom = 1 }
                Button(session.panelsHidden ? "Show panels" : "Hide panels") { session.panelsHidden.toggle() }
            } label: { HStack(spacing: 5) { Text(session.workspacePreset); Image(systemName: "chevron.down").font(.system(size: 8)) } }.menuStyle(.borderlessButton).fixedSize()
        }.font(.system(size: 11)).padding(.leading, 84).padding(.trailing, 12).frame(height: 30).background(ProTheme.header)
            .overlay(alignment: .bottom) { Rectangle().fill(ProTheme.border).frame(height: 1) }
    }
}

struct ProDocumentTab: View {
    @ObservedObject var session: StudioSession
    var tabTitle: String {
        let title = session.document.title + (session.isDirty ? " *" : "")
        let zoom = String(format: "%.1f%%", session.canvasScale * 100)
        let mode = session.tool == .pixel ? " (RGB/8)" : ""
        return "\(title) @ \(zoom)\(mode)"
    }
    var body: some View {
        if let workspace = session.workspace, workspace.usesTabs { WorkspaceDocumentTabs(workspace: workspace) }
        else {
            HStack(spacing: 0) {
                HStack(spacing: 9) {
                    Button { AppCoordinator.shared.closeDocument() } label: { Image(systemName: "xmark").font(.system(size: 8)) }.buttonStyle(.plain)
                    Text(tabTitle).font(.system(size: 11)).lineLimit(1)
                }.foregroundStyle(ProTheme.text).padding(.horizontal, 13).frame(height: 29).background(Color(hex: "3A3A3A"))
                Spacer()
            }.frame(height: 29).background(Color(hex: "222222"))
        }
    }
}

struct ForegroundColors: View {
    @ObservedObject var session: StudioSession
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Rectangle().fill(Color(hex: session.backgroundColor)).frame(width: 21, height: 21).overlay(Rectangle().stroke(.gray, lineWidth: 1)).offset(x: 6, y: 6)
                ProColorControl("Foreground color", selection: Binding(get: { Color(hex: session.drawingColor) }, set: { session.drawingColor = $0.hex }), supportsOpacity: false).labelsHidden().frame(width: 25, height: 25).offset(x: -4, y: -4)
            }.frame(width: 35, height: 35)
            HStack(spacing: 3) {
                ProIcon(symbol: "square.on.square", help: "Default colors · D", size: 16) { session.drawingColor = "000000"; session.backgroundColor = "FFFFFF" }
                ProIcon(symbol: "arrow.up.arrow.down", help: "Swap foreground/background · X", size: 16) { let foreground = session.drawingColor; session.drawingColor = session.backgroundColor; session.backgroundColor = foreground }
            }
        }.padding(.vertical, 8)
    }
}

struct ProToolRail: View {
    @ObservedObject var session: StudioSession
    var twoColumns = false
    @State private var expanded = false
    var tools: [DrawingTool] {
        switch session.tool {
        case .pixel: return [.select, .marquee, .ellipseSelect, .lasso, .crop, .eyedropper, .brush, .eraser, .pen, .text, .rectangle, .ellipse, .hand, .zoom]
        case .form: return [.select, .directSelect, .pen, .text, .line, .rectangle, .ellipse, .brush, .eyedropper, .hand, .zoom]
        case .press: return [.select, .directSelect, .text, .pen, .line, .rectangle, .ellipse, .eyedropper, .hand, .zoom]
        default: return [.select, .hand, .zoom, .rectangle, .ellipse, .pen, .text, .brush]
        }
    }
    var body: some View {
        VStack(spacing: 3) {
            Button { expanded.toggle() } label: { Image(systemName: (twoColumns != expanded) ? "chevron.left.2" : "chevron.right.2").font(.system(size: 7)).frame(height: 12).frame(maxWidth: .infinity) }.buttonStyle(.plain).foregroundStyle(ProTheme.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(27), spacing: 2), count: twoColumns != expanded ? 2 : 1), spacing: 2) {
                ForEach(tools, id: \.self) { tool in
                    ProIcon(symbol: tool.symbol, help: "\(tool.title) Tool (\(tool.shortcut))", active: session.drawingTool == tool, size: 27) { session.drawingTool = tool }
                }
            }
            ForegroundColors(session: session)
            Spacer(minLength: 0)
        }.frame(width: twoColumns != expanded ? 64 : 39).background(ProTheme.panel)
            .overlay(alignment: .trailing) { Rectangle().fill(ProTheme.border).frame(width: 1) }
    }
}

struct ProRuler: View {
    var vertical = false
    var scale: Double
    var origin: Double
    var body: some View {
        Canvas { context, size in
            let extent = vertical ? size.height : size.width
            let target = 65 / max(0.01, scale)
            let base = pow(10, floor(log10(target)))
            let multiple = target / base
            let step = max(1, base * (multiple <= 1 ? 1 : multiple <= 2 ? 2 : multiple <= 5 ? 5 : 10))
            let start = floor(-origin / scale / step) * step
            var path = Path()
            for i in 0..<Int(extent / max(1, step * scale) + 8) {
                let value = start + Double(i) * step, position = origin + value * scale
                guard position >= 0, position < extent else { continue }
                if vertical {
                    path.move(to: CGPoint(x: 14, y: position)); path.addLine(to: CGPoint(x: 20, y: position))
                    context.draw(Text("\(Int(value))").font(.system(size: 8)).foregroundColor(ProTheme.secondary), at: CGPoint(x: 7, y: position + 9))
                } else {
                    path.move(to: CGPoint(x: position, y: 14)); path.addLine(to: CGPoint(x: position, y: 20))
                    context.draw(Text("\(Int(value))").font(.system(size: 8)).foregroundColor(ProTheme.secondary), at: CGPoint(x: position + 3, y: 7), anchor: .leading)
                }
            }
            context.stroke(path, with: .color(ProTheme.secondary), lineWidth: 0.5)
        }.background(ProTheme.header)
    }
}

struct ProCanvasViewport: View {
    @ObservedObject var session: StudioSession
    var spread = false
    var body: some View {
        GeometryReader { geo in
            let pages = visiblePages
            let gutter = spread && pages.count > 1 ? 0.0 : 0.0
            let combinedWidth = session.document.width * Double(pages.count) + gutter
            let fit = min((geo.size.width - 82) / combinedWidth, (geo.size.height - 82) / session.document.height)
            let scale = max(0.01, fit * session.zoom)
            let canvasWidth = combinedWidth * scale, canvasHeight = session.document.height * scale
            ZStack(alignment: .topLeading) {
                ScrollView([.horizontal, .vertical]) {
                    HStack(spacing: gutter * scale) {
                        ForEach(pages, id: \.self) { page in
                            NativeCanvas(session: session, scale: scale, page: page)
                                .frame(width: session.document.width * scale, height: canvasHeight)
                                .overlay { if session.tool == .press && session.showGuides { PageGuideOverlay(document: session.document, scale: scale).allowsHitTesting(false) } }
                                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                        }
                    }.padding(36).frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
                if session.showRulers && session.tool != .motion {
                    ProRuler(scale: scale, origin: max(36, (geo.size.width - canvasWidth) / 2)).frame(height: 20)
                    ProRuler(vertical: true, scale: scale, origin: max(36, (geo.size.height - canvasHeight) / 2)).frame(width: 20)
                    Rectangle().fill(ProTheme.header).frame(width: 20, height: 20)
                }
            }.background(Color(hex: session.tool == .press ? "707070" : session.tool == .form ? "5C5C5C" : session.tool == .motion ? "151515" : "282828"))
                .onAppear { session.canvasScale = scale }
                .onChange(of: scale) { _, value in session.canvasScale = value }
        }
    }
    var visiblePages: [Int] {
        guard spread, session.document.pageSettings?.facingPages != false, session.page > 0 else { return [session.page] }
        let start = session.page % 2 == 1 ? session.page : session.page - 1
        return [start, start + 1].filter { $0 < session.document.pageCount }
    }
}

struct PageGuideOverlay: View {
    let document: CreativeDocument
    let scale: Double
    var body: some View {
        Canvas { context, _ in
            let settings = document.pageSettings ?? PageSettings(), margin = settings.margin
            let width = max(0, document.width - margin * 2), height = max(0, document.height - margin * 2)
            let rect = CGRect(x: margin * scale, y: margin * scale, width: width * scale, height: height * scale)
            context.stroke(Path(rect), with: .color(Color(hex: "D96DB5")), lineWidth: 0.6)
            let columns = max(1, settings.columns), columnWidth = (width - Double(columns - 1) * settings.gutter) / Double(columns)
            for i in 1..<columns {
                let x = margin + Double(i) * columnWidth + Double(i - 1) * settings.gutter
                var path = Path()
                for position in [x, x + settings.gutter] { path.move(to: CGPoint(x: position * scale, y: margin * scale)); path.addLine(to: CGPoint(x: position * scale, y: (document.height - margin) * scale)) }
                context.stroke(path, with: .color(Color(hex: "975AE5")), lineWidth: 0.6)
            }
        }
    }
}

struct ProStatusBar: View {
    @ObservedObject var session: StudioSession
    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Button("Fit on Screen") { session.zoom = 1 }
                ForEach([25, 50, 100, 200, 400], id: \.self) { percent in Button("\(percent)%") { session.zoom = Double(percent) / 100 / max(0.01, session.canvasScale / session.zoom) } }
            } label: { Text(String(format: "%.1f%%", session.canvasScale * 100)).font(.system(size: 10)).frame(width: 63) }.menuStyle(.borderlessButton)
            Rectangle().fill(ProTheme.border).frame(width: 1, height: 16)
            if session.tool == .press {
                ProIcon(symbol: "chevron.left", help: "Previous page", size: 18) { session.page = max(0, session.page - 1) }
                Text("\(session.page + 1)").frame(width: 25)
                ProIcon(symbol: "chevron.right", help: "Next page", size: 18) { session.page = min(session.document.pageCount - 1, session.page + 1) }
                let count = TextFlow.overflows(session.document).count
                Circle().fill(count > 0 ? .red : .green).frame(width: 7, height: 7)
                Text(count > 0 ? "\(count) overset text frame\(count == 1 ? "" : "s")" : "No text overflow")
            } else { Text("\(Int(session.document.width)) × \(Int(session.document.height)) px"); Text("sRGB IEC61966-2.1").foregroundStyle(ProTheme.secondary) }
            Spacer()
            if let message = session.message {
                Text(message).lineLimit(1)
                if session.lastExportURL != nil { Button("Show in Finder") { session.showInFinder() }.buttonStyle(.plain).foregroundStyle(ProTheme.blue) }
                ProIcon(symbol: "xmark", help: "Dismiss status", size: 16) { session.message = nil }
            } else { Text(session.drawingTool.title).foregroundStyle(ProTheme.secondary) }
        }.font(.system(size: 10)).foregroundStyle(ProTheme.text).padding(.horizontal, 8).frame(height: 23).background(ProTheme.panel)
    }
}
