import SwiftUI
import DevinCore

struct PixelWorkspace: View {
    @ObservedObject var session: StudioSession
    @State private var propertiesTab = "Properties"
    var body: some View {
        VStack(spacing: 0) {
            ProAppBar(session: session)
            optionsBar
            HStack(spacing: 0) {
                if !session.panelsHidden { PixelToolRail(session: session) }
                VStack(spacing: 0) { ProDocumentTab(session: session); ProCanvasViewport(session: session); ProStatusBar(session: session) }
                if !session.panelsHidden {
                    VSplitView {
                        ProColorPanel(session: session).frame(minHeight: 180, idealHeight: 225, maxHeight: 300)
                        VStack(spacing: 0) {
                            ProTabs(tabs: ["Properties", "Adjustments"], selected: $propertiesTab)
                            if propertiesTab == "Properties" { ProPropertiesPanel(session: session) }
                            else { ScrollView { ProAdjustmentsPanel(session: session) } }
                        }.frame(minHeight: 160, idealHeight: 235)
                        ProLayerPanel(session: session, pixelStyle: true).frame(minHeight: 220, idealHeight: 310)
                    }.frame(width: 298).background(ProTheme.panel)
                }
            }
        }.background(ProTheme.background).foregroundStyle(ProTheme.text)
    }
    var optionsBar: some View {
        HStack(spacing: 13) {
            Image(systemName: session.drawingTool.symbol).font(.system(size: 15)).frame(width: 22)
            Divider().frame(height: 22)
            switch session.drawingTool {
            case .select, .directSelect:
                ProCheck(title: "Auto-Select", value: $session.autoSelect)
                Text("Layer").font(.system(size: 11)).padding(.horizontal, 9).frame(height: 22).background(ProTheme.field)
                ProCheck(title: "Show Transform Controls", value: $session.showTransformControls)
                Divider().frame(height: 20)
                ForEach([("left", "align.horizontal.left"), ("horizontal", "align.horizontal.center"), ("right", "align.horizontal.right")], id: \.0) { name, symbol in ProIcon(symbol: symbol, help: "Align " + name) { session.alignSelection(name) } }
            case .brush, .eraser:
                ProField(label: "Size", value: $session.brushSize, range: 1...500, suffix: "px").frame(width: 105)
                Text("Mode: Normal").font(.system(size: 11))
                ProField(label: "Opacity", value: Binding(get: { session.brushOpacity * 100 }, set: { session.brushOpacity = $0 / 100 }), range: 1...100, suffix: "%").frame(width: 127)
                ProField(label: "Hardness", value: Binding(get: { session.brushHardness * 100 }, set: { session.brushHardness = $0 / 100 }), range: 0...100, suffix: "%").frame(width: 120)
                if session.selected?.maskData != nil { ProCheck(title: "Paint Mask", value: $session.editingMask) }
                ProIcon(symbol: "arrow.counterclockwise", help: "Reset brush") { session.brushSize = 12; session.brushOpacity = 1 }
            case .freeformPen:
                Text("Freeform Pen").font(.system(size: 11))
                ProField(label: "Curve Fit", value: $session.freeformCurveFit, range: FreeformPathStroke.curveFitRange, suffix: "px").frame(width: 140)
                Text("Drag to draw. Release to create a path. Return to the start to close. Esc cancels.").font(.system(size: 11)).foregroundStyle(ProTheme.secondary)
            case .text:
                Picker("Font", selection: session.elementBinding(\.fontName, "HelveticaNeue-Bold")) { ForEach(["HelveticaNeue-Bold", "HelveticaNeue", "Georgia", "AvenirNext-DemiBold", "Didot"], id: \.self) { Text($0).tag($0) } }.labelsHidden().frame(width: 175).controlSize(.small)
                ProField(label: "Size", value: session.elementBinding(\.fontSize, 64), range: 1...1000, suffix: "pt").frame(width: 108)
                ProColorControl("Color", selection: session.elementColor(\.fill), supportsOpacity: false).labelsHidden().frame(width: 34)
            case .marquee, .ellipseSelect, .lasso:
                Text(session.drawingTool.title).font(.system(size: 11))
                Picker("Selection mode", selection: $session.selectionMode) { ForEach(SelectionCombineMode.allCases, id: \.self) { Text($0.title).tag($0) } }.labelsHidden().frame(width: 115).controlSize(.small)
                Button("Inverse") { session.invertSelection() }.buttonStyle(ProButtonStyle()).disabled(session.effectiveSelectionPath == nil)
                if let rect = session.selectionRect { Text("W: \(Int(rect.width)) px    H: \(Int(rect.height)) px").font(.system(size: 11)) }
                Button("Deselect") { session.selectionRect = nil }.buttonStyle(ProButtonStyle())
                Button("Create Layer Mask") { session.addMask() }.buttonStyle(ProButtonStyle()).disabled(session.selected?.kind != .image)
            case .singleRow, .singleColumn, .polygonLasso, .selectionBrush, .magicWand, .pencil, .cloneStamp, .healingBrush, .patternStamp, .historyBrush, .backgroundEraser, .magicEraser, .gradient, .paintBucket, .blur, .sharpen, .dodge, .burn, .sponge, .colorReplacement, .colorSampler, .ruler, .eyedropper:
                PixelRasterOptions(session: session)
            case .polygon:
                Stepper("Sides: \(session.pixelSettings.polygonSides)", value: $session.pixelSettings.polygonSides, in: 3...50).font(.system(size: 11)).frame(width: 130)
            case .crop:
                Text("Unconstrained").font(.system(size: 11))
                Text("Drag to crop the canvas. Original layer pixels are retained.").font(.system(size: 11)).foregroundStyle(ProTheme.secondary)
            default:
                Text(session.drawingTool.title).font(.system(size: 11))
                ProColorControl("Fill", selection: Binding(get: { drawingColor }, set: { drawingColor = $0 }), supportsOpacity: false).font(.system(size: 11)).frame(width: 100)
                if [.rectangle, .ellipse, .line, .pen].contains(session.drawingTool) { ProField(label: "Stroke", value: session.elementBinding(\.strokeWidth, 2), range: 0...100, suffix: "px").frame(width: 110) }
            }
            Spacer(minLength: 5)
            Button("Save") { _ = session.save() }.buttonStyle(ProButtonStyle())
            Button("Export") { session.showExport = true }.buttonStyle(ProButtonStyle(prominent: true))
        }.padding(.horizontal, 12).frame(height: 39).background(ProTheme.panel)
            .overlay(alignment: .bottom) { Rectangle().fill(ProTheme.border).frame(height: 1) }
    }
    private var drawingColor: Color {
        get { Color(hex: session.drawingColor) }
        nonmutating set { session.drawingColor = newValue.hex }
    }
}
