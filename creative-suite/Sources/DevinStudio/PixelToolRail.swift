import SwiftUI
import DevinCore

struct PixelToolChoice: Identifiable {
    var id: String { title }
    let title: String
    let tool: DrawingTool?
    init(_ tool: DrawingTool) { self.tool = tool; title = tool.title }
    init(missing title: String) { self.title = title; tool = nil }
}
struct PixelToolGroup: Identifiable {
    var id: String { name }
    let name: String
    let shortcut: String
    let symbol: String
    let choices: [PixelToolChoice]
    var tools: [DrawingTool] { choices.compactMap(\.tool) }
}
enum PixelToolbar {
    static let groups: [PixelToolGroup] = [
        .init(name: "Move", shortcut: "V", symbol: "arrow.up.and.down.and.arrow.left.and.right", choices: [.init(.select), .init(missing: "Artboard")]),
        .init(name: "Marquee", shortcut: "M", symbol: "rectangle.dashed", choices: [.init(.marquee), .init(.ellipseSelect), .init(.singleRow), .init(.singleColumn)]),
        .init(name: "Selection Brush", shortcut: "", symbol: "paintbrush.pointed", choices: [.init(.selectionBrush)]),
        .init(name: "Object / Color Selection", shortcut: "W", symbol: "wand.and.stars", choices: [.init(.magicWand), .init(missing: "Object Selection"), .init(missing: "Quick Selection")]),
        .init(name: "Lasso", shortcut: "L", symbol: "lasso", choices: [.init(.lasso), .init(.polygonLasso), .init(missing: "Magnetic Lasso")]),
        .init(name: "Crop", shortcut: "C", symbol: "crop", choices: [.init(.crop), .init(missing: "Perspective Crop"), .init(missing: "Slice"), .init(missing: "Slice Select")]),
        .init(name: "Frame", shortcut: "K", symbol: "rectangle", choices: [.init(missing: "Frame")]),
        .init(name: "Sampling", shortcut: "I", symbol: "eyedropper", choices: [.init(.eyedropper), .init(.colorSampler), .init(.ruler), .init(missing: "Note"), .init(missing: "Count")]),
        .init(name: "Retouch", shortcut: "J", symbol: "bandage", choices: [.init(.healingBrush), .init(missing: "Spot Healing"), .init(missing: "Remove"), .init(missing: "Patch"), .init(missing: "Content-Aware Move"), .init(missing: "Red Eye")]),
        .init(name: "Brush", shortcut: "B", symbol: "paintbrush.pointed", choices: [.init(.brush), .init(.pencil), .init(.colorReplacement), .init(missing: "Mixer Brush")]),
        .init(name: "Stamp", shortcut: "S", symbol: "seal.fill", choices: [.init(.cloneStamp), .init(.patternStamp)]),
        .init(name: "History", shortcut: "Y", symbol: "clock.arrow.circlepath", choices: [.init(.historyBrush), .init(missing: "Art History Brush")]),
        .init(name: "Eraser", shortcut: "E", symbol: "eraser", choices: [.init(.eraser), .init(.backgroundEraser), .init(.magicEraser)]),
        .init(name: "Fill", shortcut: "G", symbol: "rectangle.lefthalf.filled", choices: [.init(.gradient), .init(.paintBucket)]),
        .init(name: "Detail", shortcut: "", symbol: "drop", choices: [.init(.blur), .init(.sharpen), .init(missing: "Smudge")]),
        .init(name: "Tone", shortcut: "O", symbol: "circle.lefthalf.filled", choices: [.init(.dodge), .init(.burn), .init(.sponge)]),
        .init(name: "Pen", shortcut: "P", symbol: "pencil.tip.crop.circle", choices: [.init(.pen), .init(.freeformPen), .init(missing: "Curvature Pen"), .init(.addAnchor), .init(.deleteAnchor), .init(.convertAnchor)]),
        .init(name: "Type", shortcut: "T", symbol: "textformat", choices: [.init(.text), .init(missing: "Vertical Type"), .init(missing: "Horizontal Type Mask"), .init(missing: "Vertical Type Mask")]),
        .init(name: "Paths", shortcut: "A", symbol: "cursorarrow", choices: [.init(.directSelect), .init(missing: "Path Selection of subpaths")]),
        .init(name: "Shapes", shortcut: "U", symbol: "rectangle", choices: [.init(.rectangle), .init(.roundedRectangle), .init(.ellipse), .init(.polygon), .init(.line), .init(missing: "Custom Shape")]),
        .init(name: "Navigation", shortcut: "H", symbol: "hand.draw", choices: [.init(.hand), .init(missing: "Rotate View")]),
        .init(name: "Zoom", shortcut: "Z", symbol: "magnifyingglass", choices: [.init(.zoom)])
    ]
    static func nextTool(key: String, current: DrawingTool, cycling: Bool) -> DrawingTool? {
        guard !key.isEmpty, let group = groups.first(where: { $0.shortcut == key }), !group.tools.isEmpty else { return nil }
        if let index = group.tools.firstIndex(of: current) { return cycling ? group.tools[(index + 1) % group.tools.count] : current }
        return group.tools.first
    }
}

struct PixelToolRail: View {
    @ObservedObject var session: StudioSession
    @State private var twoColumns = false

    var body: some View {
        VStack(spacing: 4) {
            Button { twoColumns.toggle() } label: { Image(systemName: twoColumns ? "chevron.left.2" : "chevron.right.2").font(.system(size: 8)).frame(height: 13) }.buttonStyle(.plain)
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(29), spacing: 3), count: twoColumns ? 2 : 1), spacing: 2) {
                    ForEach(PixelToolbar.groups) { group in PixelToolGroupButton(session: session, group: group) }
                }.padding(.vertical, 2)
            }.scrollIndicators(.hidden)
            Button { session.showFeatureInventory = true } label: { Image(systemName: "ellipsis").frame(width: 29, height: 22) }.buttonStyle(.plain).help("Feature parity ledger and missing tools")
            ForegroundColors(session: session)
            Button { session.showGrid.toggle() } label: { Image(systemName: "grid").frame(width: 29, height: 24) }.buttonStyle(.plain).help("Pixel grid")
            Button { session.panelsHidden.toggle() } label: { Image(systemName: "rectangle.on.rectangle").frame(width: 29, height: 24) }.buttonStyle(.plain).help("Hide panels · Tab")
        }.padding(.vertical, 4).frame(width: twoColumns ? 71 : 43).background(Color(hex: "515151")).foregroundStyle(.white)
    }
}

struct PixelToolGroupButton: NSViewRepresentable {
    @ObservedObject var session: StudioSession
    let group: PixelToolGroup
    func makeNSView(context: Context) -> GroupedToolControl { GroupedToolControl(session: session, group: group) }
    func updateNSView(_ view: GroupedToolControl, context: Context) { view.session = session; view.needsDisplay = true; view.updateHelp() }
}
