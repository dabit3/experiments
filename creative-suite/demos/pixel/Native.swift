// Native computer use only. No link to, or injection into, Pixel's model.
import AppKit
import ApplicationServices

let args = CommandLine.arguments
struct LiveState: Codable {
    var status: String
    var title: String
    var source: String
    var checks: [String]
}
struct NativeNode: Encodable {
    let index: Int
    let rect: [Double]
    let role: String?
    let title: String?
    let description: String?
    let value: String?
    let placeholder: String?
    let enabled: String?
    enum CodingKeys: String, CodingKey {
        case index, rect
        case role = "AXRole", title = "AXTitle", description = "AXDescription"
        case value = "AXValue", placeholder = "AXPlaceholderValue", enabled = "AXEnabled"
    }
}
func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
    var result: CFTypeRef?
    AXUIElementCopyAttributeValue(element, key as CFString, &result)
    return result
}
func descendants(_ root: AXUIElement, depth: Int = 0) -> [AXUIElement] {
    guard depth < 18 else { return [] }
    return [root] + (attribute(root, "AXChildren") as? [AXUIElement] ?? [])
        .flatMap { descendants($0, depth: depth + 1) }
}
func rectangle(_ element: AXUIElement) -> CGRect {
    var point = CGPoint.zero, size = CGSize.zero
    if let v = attribute(element, "AXPosition") { AXValueGetValue(v as! AXValue, .cgPoint, &point) }
    if let v = attribute(element, "AXSize") { AXValueGetValue(v as! AXValue, .cgSize, &size) }
    return CGRect(origin: point, size: size)
}
func pixel() -> NSRunningApplication {
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "ai.devin.creative.pixel").first else {
        fatalError("Launch the packaged Devin Pixel first")
    }
    return app
}
func nodes() -> [AXUIElement] {
    let root = AXUIElementCreateApplication(pixel().processIdentifier)
    return (attribute(root, "AXWindows") as? [AXUIElement] ?? []).flatMap { descendants($0) }
}
func emitMouse(_ type: CGEventType, _ point: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
}
func glide(_ target: CGPoint) {
    let start = CGEvent(source: nil)!.location
    for i in 1...18 {
        let t = Double(i) / 18
        emitMouse(.mouseMoved, CGPoint(x: start.x + (target.x-start.x)*t, y: start.y + (target.y-start.y)*t))
        usleep(14000)
    }
}
func click(_ point: CGPoint) {
    glide(point); emitMouse(.leftMouseDown, point); usleep(80000); emitMouse(.leftMouseUp, point); usleep(150000)
}
func key(_ code: CGKeyCode, _ flags: CGEventFlags = []) {
    for down in [true, false] {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
        event.flags = down ? flags : []; event.post(tap: .cghidEventTap); usleep(45000)
    }
}
func typeText(_ text: String) {
    for character in text {
        let units = Array(String(character).utf16)
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        event.flags = []
        units.withUnsafeBufferPointer { event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: $0.baseAddress!) }
        event.post(tap: .cghidEventTap)
        let up = event.copy()!; up.type = .keyUp; up.post(tap: .cghidEventTap)
        usleep(22000)
    }
}

final class LabView: NSView {
    var state = LiveState(status:"READY",title:"Awaiting native test runner",source:"# Native test runner ready",checks:[])
    override var isFlipped: Bool { true }
    func text(_ string: String, _ rect: CGRect, _ size: CGFloat, _ color: NSColor, mono: Bool = false, bold: Bool = false) {
        let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: bold ? .semibold : .regular) : NSFont.systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        let style = NSMutableParagraphStyle(); style.lineSpacing = 5
        (string as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(srgbRed: 0.045, green: 0.065, blue: 0.09, alpha: 1).setFill(); bounds.fill()
        let mint = NSColor(srgbRed: 0.52, green: 0.9, blue: 0.76, alpha: 1)
        let muted = NSColor(srgbRed: 0.55, green: 0.62, blue: 0.69, alpha: 1)
        text("PIXEL  /  LIVE LAB", CGRect(x: 26,y: 30,width: 420,height: 35), 17, mint, mono: true, bold: true)
        text("After hours.", CGRect(x: 26,y: 78,width: 420,height: 60), 38, .white, bold: true)
        text("Native image-making • executable evidence", CGRect(x: 26,y: 134,width: 420,height: 30), 14, muted)
        let status = state.status
        let color: NSColor = status == "FAILED" ? .systemRed : mint
        text(status, CGRect(x:26,y:193,width:420,height:26), 13,color,mono:true,bold:true)
        text(state.title, CGRect(x:26,y:225,width:420,height:65), 23,.white,bold:true)
        text("ACTUAL EXECUTING SOURCE  /  demo.py", CGRect(x:26,y:306,width:420,height:25), 11,muted,mono:true)
        NSColor.white.withAlphaComponent(0.055).setFill()
        NSBezierPath(roundedRect:CGRect(x:16,y:338,width:bounds.width-32,height:445),xRadius:10,yRadius:10).fill()
        let source = state.source
        text(source, CGRect(x:28,y:357,width:bounds.width-48,height:422), 14,mint,mono:true)
        text("ASSERTIONS  /  LIVE RESULTS", CGRect(x:26,y:813,width:420,height:25),11,muted,mono:true)
        let checks = state.checks
        text(checks.suffix(5).joined(separator:"\n"), CGRect(x:26,y:850,width:bounds.width-50,height:200),14,.white,mono:true)
        text("Starting input: generated landscape PNG.\nAll finishing edits: real Pixel UI.\nCGEvent + Accessibility • no model injection", CGRect(x:26,y:1060,width:bounds.width-45,height:70),12,muted)
    }
}
if args[1] == "viewer" {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let height = NSScreen.main!.frame.height
    let window = NSWindow(contentRect: CGRect(x:1128,y:height-1175,width:472,height:1140),styleMask:[.borderless],backing:.buffered,defer:false)
    window.backgroundColor = .black
    window.level = .normal
    let view = LabView(frame: window.contentView!.bounds); window.contentView = view
    window.orderFrontRegardless()
    Timer.scheduledTimer(withTimeInterval:0.15,repeats:true) { _ in
        if let data = try? Data(contentsOf:URL(fileURLWithPath:args[2])),
           let state = try? JSONDecoder().decode(LiveState.self,from:data) {
            view.state = state; view.needsDisplay = true
        }
    }
    app.run()
} else {
    guard AXIsProcessTrusted(), CGPreflightScreenCaptureAccess() else { fatalError("Accessibility and Screen Recording permissions required") }
    switch args[1] {
    case "selectText":
        let element = nodes()[Int(args[2])!]
        let value = attribute(element,"AXValue") as? String ?? ""
        var range = CFRange(location:0,length:value.utf16.count)
        let result = AXUIElementSetAttributeValue(element,"AXSelectedTextRange" as CFString,AXValueCreate(.cfRange,&range)!)
        guard result == .success else { fatalError("Cannot select native field text: \(result)") }
        usleep(200000)
    case "panel":
        let root = AXUIElementCreateApplication(pixel().processIdentifier)
        let window = (attribute(root,"AXWindows") as! [AXUIElement])[0]
        var p = CGPoint(x:120,y:300)
        AXUIElementSetAttributeValue(window,"AXPosition" as CFString,AXValueCreate(.cgPoint,&p)!)
    case "list":
        let result = nodes().enumerated().map { index, element in
            func string(_ key: String) -> String? { attribute(element,key).map { "\($0)" } }
            let r = rectangle(element)
            return NativeNode(index:index,rect:[r.minX,r.minY,r.width,r.height],
                role:string("AXRole"),title:string("AXTitle"),description:string("AXDescription"),
                value:string("AXValue"),placeholder:string("AXPlaceholderValue"),enabled:string("AXEnabled"))
        }
        print(String(data:try! JSONEncoder().encode(result),encoding:.utf8)!)
    case "frame":
        let root = AXUIElementCreateApplication(pixel().processIdentifier)
        let window = (attribute(root,"AXWindows") as! [AXUIElement])[0]
        var p = CGPoint(x:0,y:35), s = CGSize(width:1120,height:1140)
        AXUIElementSetAttributeValue(window,"AXPosition" as CFString,AXValueCreate(.cgPoint,&p)!)
        AXUIElementSetAttributeValue(window,"AXSize" as CFString,AXValueCreate(.cgSize,&s)!)
    case "activate": pixel().activate(options:[]); usleep(250000)
    case "click":
        click(CGPoint(x:Double(args[2])!, y:Double(args[3])!))
    case "key":
        var flags: CGEventFlags = []
        if args.count > 3 {
            if args[3].contains("cmd") { flags.insert(.maskCommand) }
            if args[3].contains("shift") { flags.insert(.maskShift) }
            if args[3].contains("alt") { flags.insert(.maskAlternate) }
        }
        key(CGKeyCode(args[2])!,flags)
    case "type": typeText(args[2])
    case "move": glide(CGPoint(x:Double(args[2])!,y:Double(args[3])!))
    case "drag":
        let points = try! JSONDecoder().decode([[Double]].self,from:Data(args[2].utf8))
        let pts = points.map { CGPoint(x:$0[0],y:$0[1]) }
        glide(pts[0]); emitMouse(.leftMouseDown,pts[0])
        for i in 1..<pts.count {
            let start = pts[i-1], end = pts[i]
            for j in 1...20 {
                let t = Double(j)/20
                emitMouse(.leftMouseDragged, CGPoint(x:start.x+(end.x-start.x)*t,y:start.y+(end.y-start.y)*t))
                usleep(15000)
            }
        }
        usleep(250000)
        if args.count > 3 {
            let p = Process(); p.executableURL=URL(fileURLWithPath:"/usr/sbin/screencapture"); p.arguments=["-x",args[3]]
            try! p.run(); p.waitUntilExit()
        }
        emitMouse(.leftMouseUp,pts.last!); usleep(350000)
    case "scroll":
        CGEvent(scrollWheelEvent2Source:nil,units:.pixel,wheelCount:1,wheel1:Int32(args[2])!,wheel2:0,wheel3:0)?.post(tap:.cghidEventTap)
    default: fatalError("Unknown command")
    }
}
