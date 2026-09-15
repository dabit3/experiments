import AppKit

final class GroupedToolControl: NSControl {
    var session: StudioSession
    let group: PixelToolGroup
    var menuPresenter: ((NSMenu) -> Void)?
    private var hold: DispatchWorkItem?
    private var pressed = false
    var current: DrawingTool? { group.tools.contains(session.drawingTool) ? session.drawingTool : session.pixelToolMemory[group.id] ?? group.tools.first }
    var active: Bool { group.tools.contains(session.drawingTool) }
    var arrowRect: CGRect { CGRect(x: bounds.maxX - 11, y: bounds.maxY - 11, width: 11, height: 11) }
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 29, height: 27) }
    init(session: StudioSession, group: PixelToolGroup) {
        self.session = session; self.group = group
        super.init(frame: CGRect(x: 0, y: 0, width: 29, height: 27))
        identifier = NSUserInterfaceItemIdentifier("tool-group." + group.id)
        setAccessibilityElement(true); setAccessibilityRole(.button)
        setAccessibilityLabel(group.name + " tools")
        updateHelp()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    deinit { hold?.cancel() }
    func updateHelp() {
        toolTip = (current?.title ?? group.name + " — not implemented") + (group.shortcut.isEmpty ? "" : " (" + group.shortcut + ")") + ". Click the triangle, hold, or right-click to choose a tool."
        setAccessibilityHelp(toolTip)
    }
    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        if active || pressed {
            NSColor.black.withAlphaComponent(0.28).setFill(); NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
            NSColor.white.withAlphaComponent(0.45).setStroke(); NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).stroke()
        }
        let color = NSColor.white.withAlphaComponent(current == nil ? 0.35 : 1)
        let configuration = NSImage.SymbolConfiguration(pointSize: 19, weight: .regular).applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        if let image = NSImage(systemSymbolName: current?.symbol ?? group.symbol, accessibilityDescription: nil)?.withSymbolConfiguration(configuration) {
            image.draw(in: CGRect(x: (bounds.width - 21) / 2, y: 2, width: 21, height: 21), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        if group.choices.count > 1 {
            let triangle = NSBezierPath(); triangle.move(to: CGPoint(x: bounds.maxX - 7, y: bounds.maxY - 6)); triangle.line(to: CGPoint(x: bounds.maxX - 2, y: bounds.maxY - 6)); triangle.line(to: CGPoint(x: bounds.maxX - 2, y: bounds.maxY - 2)); triangle.close()
            NSColor.white.setFill(); triangle.fill()
        }
    }
    override func mouseDown(with event: NSEvent) {
        hold?.cancel()
        if event.modifierFlags.contains(.control) || (group.choices.count > 1 && arrowRect.contains(convert(event.locationInWindow, from: nil))) { showChoices(); return }
        pressed = true; needsDisplay = true
        if group.choices.count > 1 {
            let action = DispatchWorkItem { [weak self] in guard let self, self.pressed else { return }; self.showChoices() }
            hold = action; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: action)
        }
    }
    override func mouseUp(with event: NSEvent) {
        hold?.cancel(); hold = nil
        let shouldSelect = pressed && bounds.contains(convert(event.locationInWindow, from: nil))
        pressed = false; needsDisplay = true
        if shouldSelect { if let current { choose(current) } else { session.showFeatureInventory = true } }
    }
    override func mouseDragged(with event: NSEvent) {
        if !bounds.contains(convert(event.locationInWindow, from: nil)) { hold?.cancel(); pressed = false; needsDisplay = true }
    }
    override func rightMouseDown(with event: NSEvent) { showChoices() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 125 || event.keyCode == 49 { showChoices() } else { super.keyDown(with: event) }
    }
    override func accessibilityPerformPress() -> Bool { showChoices(); return true }
    func makeChoicesMenu() -> NSMenu {
        let menu = NSMenu(title: group.name); menu.autoenablesItems = false
        for choice in group.choices {
            let item = NSMenuItem(title: choice.title + (choice.tool == nil ? " — Not implemented" : ""), action: #selector(selectTool(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = choice.tool?.rawValue; item.isEnabled = choice.tool != nil
            item.state = choice.tool != nil && choice.tool == current ? .on : .off
            if let tool = choice.tool { item.image = NSImage(systemSymbolName: tool.symbol, accessibilityDescription: nil) }
            menu.addItem(item)
        }
        return menu
    }
    func showChoices() {
        hold?.cancel(); hold = nil; pressed = false; needsDisplay = true
        let menu = makeChoicesMenu()
        if let menuPresenter { menuPresenter(menu) }
        else { menu.popUp(positioning: nil, at: CGPoint(x: bounds.maxX + 3, y: bounds.minY), in: self) }
    }
    @objc func selectTool(_ item: NSMenuItem) {
        guard let value = item.representedObject as? String, let tool = DrawingTool(rawValue: value), group.tools.contains(tool) else { return }
        choose(tool)
    }
    func choose(_ tool: DrawingTool) {
        session.pixelToolMemory[group.id] = tool; session.drawingTool = tool
        if tool == .pencil { session.brushSize = 1 }
        needsDisplay = true; updateHelp()
    }
}
