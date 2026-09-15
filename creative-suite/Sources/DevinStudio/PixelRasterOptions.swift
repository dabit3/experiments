import SwiftUI
import DevinCore

struct PixelRasterOptions: View {
    @ObservedObject var session: StudioSession
    var tool: DrawingTool { session.drawingTool }
    var body: some View {
        HStack(spacing: 10) {
            Text(tool.title).font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
            if PixelRasterTools.strokes.contains(tool) || tool == .selectionBrush {
                ProField(label: "Size", value: $session.brushSize, range: 1...500, suffix: "px").frame(width: 95)
            }
            if PixelRasterTools.strokes.contains(tool) || PixelRasterTools.fills.contains(tool) {
                ProField(label: "Opacity", value: Binding(get: { session.brushOpacity * 100 }, set: { session.brushOpacity = $0 / 100 }), range: 0...100, suffix: "%").frame(width: 115)
            }
            switch tool {
            case .cloneStamp, .healingBrush:
                ProCheck(title: "Aligned", value: $session.pixelSettings.aligned)
                Text(session.cloneSource == nil ? "Option-click to sample" : "Source set").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
                Button("Reset Source") { session.cloneSource = nil; session.cloneOffset = nil }.buttonStyle(ProButtonStyle())
            case .patternStamp:
                Button("Set Pattern") { session.patternSource = session.selected }.buttonStyle(ProButtonStyle()).disabled(session.selected?.kind != .image)
                Text(session.patternSource?.name ?? "No pattern source").font(.system(size: 10)).lineLimit(1).frame(maxWidth: 150)
            case .historyBrush:
                Button("Set History Source") { session.historyPaintSource = session.selected }.buttonStyle(ProButtonStyle()).disabled(session.selected?.kind != .image)
                Text(session.historyPaintSource == nil ? "No source" : "Layer snapshot set").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
            case .magicWand, .paintBucket, .magicEraser, .backgroundEraser, .colorReplacement:
                ProField(label: "Tolerance", value: $session.pixelSettings.tolerance, range: 0...255).frame(width: 125)
                if [.magicWand, .paintBucket, .magicEraser].contains(tool) { ProCheck(title: "Contiguous", value: $session.pixelSettings.contiguous) }
            case .gradient:
                Picker("Style", selection: $session.pixelSettings.radialGradient) { Text("Linear").tag(false); Text("Radial").tag(true) }.labelsHidden().controlSize(.small).frame(width: 110)
                Text("Foreground → Background").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
            case .blur, .sharpen, .dodge, .burn, .sponge:
                ProField(label: "Strength", value: Binding(get: { session.pixelSettings.strength * 100 }, set: { session.pixelSettings.strength = $0 / 100 }), range: 0...100, suffix: "%").frame(width: 122)
                if tool == .sponge { ProCheck(title: "Saturate", value: $session.pixelSettings.saturate) }
            case .singleRow, .singleColumn, .polygonLasso, .selectionBrush:
                Picker("Mode", selection: $session.selectionMode) { ForEach(SelectionCombineMode.allCases, id: \.self) { Text($0.title).tag($0) } }.labelsHidden().controlSize(.small).frame(width: 105)
                if tool == .polygonLasso { Text("Click vertices · Return to close · Escape to cancel").font(.system(size: 10)).foregroundStyle(ProTheme.secondary) }
            case .colorSampler, .eyedropper:
                Picker("Sample", selection: $session.pixelSettings.sampleRadius) { Text("Point sample").tag(0); Text("3 × 3 average").tag(1); Text("5 × 5 average").tag(2); Text("11 × 11 average").tag(5) }.labelsHidden().controlSize(.small).frame(width: 140)
                if tool == .colorSampler {
                    ForEach(Array(session.colorSamples.suffix(4).enumerated()), id: \.element.id) { index, sample in Text("\(index + 1): #\(sample.color)").font(.system(size: 9, design: .monospaced)) }
                    Button("Clear Samples") { session.colorSamples = [] }.buttonStyle(ProButtonStyle())
                }
            case .ruler:
                if let line = session.measurement {
                    let dx = line.end.x - line.start.x, dy = line.end.y - line.start.y
                    Text(String(format: "X %.1f   Y %.1f   W %.1f   H %.1f   L %.1f px   Angle %.1f°", line.start.x, line.start.y, dx, dy, hypot(dx, dy), atan2(dy, dx) * 180 / .pi)).font(.system(size: 10, design: .monospaced))
                } else { Text("Drag to measure distance and angle").font(.system(size: 10)) }
            default: EmptyView()
            }
        }
    }
}
