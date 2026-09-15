import AppKit
import SwiftUI

final class RectangularColorWell: NSColorWell {
    override var intrinsicContentSize: NSSize { NSSize(width: 24, height: 20) }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(hex: "171717").setFill(); bounds.fill()
        color.setFill(); bounds.insetBy(dx: 2, dy: 2).fill()
        NSColor(hex: "9B9B9B").setStroke(); NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
    }
    override func mouseDown(with event: NSEvent) {
        NSColorPanel.shared.showsAlpha = false
        activate(true)
        NSColorPanel.shared.orderFront(nil)
    }
}

struct ProColorWell: NSViewRepresentable {
    @Binding var selection: Color
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> RectangularColorWell {
        let view = RectangularColorWell(); view.color = NSColor(selection); view.target = context.coordinator; view.action = #selector(Coordinator.changed(_:)); return view
    }
    func updateNSView(_ view: RectangularColorWell, context: Context) { context.coordinator.parent = self; view.color = NSColor(selection); view.needsDisplay = true }
    final class Coordinator: NSObject {
        var parent: ProColorWell
        init(_ parent: ProColorWell) { self.parent = parent }
        @objc func changed(_ sender: NSColorWell) { parent.selection = Color(nsColor: sender.color) }
    }
}

struct ProColorControl: View {
    let title: String
    @Binding var selection: Color
    init(_ title: String, selection: Binding<Color>, supportsOpacity: Bool = false) { self.title = title; self._selection = selection }
    var body: some View {
        LabeledContent { ProColorWell(selection: $selection).frame(width: 24, height: 20) } label: { Text(title).font(.system(size: 10)) }
    }
}
