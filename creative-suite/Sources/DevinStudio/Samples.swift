import Foundation
import DevinCore

enum Samples {
    static func document(for tool: StudioTool, blank: Bool = false) -> CreativeDocument {
        var d = CreativeDocument(title: blank ? "Untitled" : title(for: tool), tool: tool)
        if tool == .press { d.width = 840; d.height = 1120 }
        if tool == .motion { d.width = 1280; d.height = 720; d.background = "202920" }
        if tool == .frame { d.width = 800; d.height = 800 }
        if blank { return d }
        switch tool {
        case .pixel, .form: poster(&d)
        case .press: editorial(&d)
        case .lens:
            d.width = 1400; d.height = 1000
            d.background = "E1D9C8"
            landscape(&d)
        case .motion: motion(&d)
        case .frame: frames(&d)
        case .code:
            d.html = "<main>\n  <nav><strong>FIELDNOTES®</strong><span>Independent by nature.</span></nav>\n  <section><p class=\"eyebrow\">A SMALL STUDIO FOR BIG IDEAS</p>\n    <h1>Stay curious.<br>Make things.</h1>\n    <p>Good things happen at the intersection of intention and play.</p>\n    <button id=\"hello\">Take a closer look ↗</button>\n  </section>\n  <div class=\"orb\"></div>\n  <footer>DESIGNED IN DEVIN CODE <span>01 — ∞</span></footer>\n</main>"
            d.css = "* { box-sizing: border-box; }\nbody { margin: 0; background: #eeeade; color: #22291e; font-family: -apple-system, sans-serif; }\nmain { min-height: 100vh; padding: 36px 7%; position: relative; overflow: hidden; }\nnav, footer { display: flex; justify-content: space-between; font-size: 11px; letter-spacing: 1px; }\nsection { position: relative; z-index: 1; margin: 110px 0; max-width: 560px; }\n.eyebrow { font-size: 10px; letter-spacing: 2px; }\nh1 { font-size: clamp(54px, 8vw, 110px); line-height: .95; letter-spacing: -6px; margin: 26px 0; font-weight: 600; }\np { font-size: 15px; line-height: 1.7; max-width: 310px; }\nbutton { border: 0; border-radius: 30px; padding: 16px 24px; background: #22291e; color: #eeeade; cursor: pointer; margin-top: 15px; }\n.orb { position: absolute; width: 400px; height: 400px; right: -70px; top: 200px; border-radius: 50%; background: radial-gradient(circle at 30% 25%, #d9f79e, #6d8c31 45%, #25351b 75%); box-shadow: -20px 25px 60px #24300f33; }\nfooter { position: relative; z-index: 1; margin-top: 50px; }"
            d.javascript = "document.querySelector('#hello').addEventListener('click', () => {\n  document.querySelector('h1').textContent = 'You made this.';\n});"
        case .space:
            var sphere = SpatialObject(name: "Sage / sphere", primitive: "sphere")
            sphere.x = -1.2; sphere.y = 0.1; sphere.color = "C5D7A9"
            var torus = SpatialObject(name: "Clay / torus", primitive: "torus")
            torus.x = 1.3; torus.y = 0.15; torus.color = "D4957C"; torus.rotation = 35; torus.metalness = 0.65
            var box = SpatialObject(name: "Chalk / cube", primitive: "box")
            box.y = -0.25; box.z = -1.5; box.scale = 0.8; box.rotation = -20; box.color = "E6E0D3"
            d.objects = [sphere, torus, box]
        case .cut, .sound, .folio, .batch: break
        }
        return d
    }
    static func title(for tool: StudioTool) -> String {
        switch tool {
        case .pixel, .form: return "Off the grid"
        case .press: return "The quiet issue"
        case .lens: return "Somewhere, slowly"
        case .motion: return "A new perspective"
        case .frame: return "Orbital studies"
        case .code: return "Fieldnotes — a small studio"
        case .space: return "Objects of intention"
        default: return "Untitled \(tool.rawValue)"
        }
    }
    static func shape(_ kind: ElementKind, _ name: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ fill: String, page: Int = 0) -> CanvasElement {
        CanvasElement(kind: kind, name: name, x: x, y: y, width: w, height: h, fill: fill, page: page)
    }
    static func text(_ value: String, _ x: Double, _ y: Double, _ size: Double, _ color: String, width: Double = 1000, page: Int = 0) -> CanvasElement {
        var e = shape(.text, value.components(separatedBy: "\n").first ?? "Text", x, y, width, size * Double(value.components(separatedBy: "\n").count) * 1.3, color, page: page)
        e.text = value; e.fontSize = size
        return e
    }
    static func poster(_ d: inout CreativeDocument) {
        d.background = "EAE6DA"
        d.elements = [
            text("DEVIN DESIGN EXPLORATIONS", 65, 52, 14, "353C30"),
            text("VOL. 001  /  INDEPENDENT BY NATURE", 758, 52, 12, "353C30", width: 410),
            shape(.rectangle, "Midnight field", 570, 140, 570, 615, "283A2B"),
            shape(.ellipse, "Chartreuse sun", 655, 185, 390, 390, "D4E695"),
            shape(.ellipse, "Shadow study", 737, 250, 240, 240, "283A2B"),
            shape(.rectangle, "Clay plane", 675, 560, 330, 100, "DDA98A"),
            text("Off\nthe grid.", 55, 190, 120, "283A2B", width: 650),
            text("A little less ordinary.\nA little more you.", 66, 590, 27, "495441", width: 470),
            text("FORM / COLOR / POSSIBILITY", 65, 812, 13, "353C30"),
            text("MAKE YOUR OWN WAY  ↗", 883, 812, 13, "353C30", width: 290)
        ]
        d.elements[5].rotation = -18
    }
    static func editorial(_ d: inout CreativeDocument) {
        d.pageCount = 3; d.background = "F1EDE3"
        for page in 0..<3 {
            d.elements.append(text("STILL / A JOURNAL OF INTENTIONAL LIVING", 58, 48, 12, "354335", width: 750, page: page))
            d.elements.append(text(String(format: "%02d", page + 1), 730, 1050, 15, "354335", width: 60, page: page))
        }
        d.elements += [text("The\nquiet\nissue.", 48, 125, 136, "354335", width: 750),
                       shape(.rectangle, "Forest", 58, 660, 724, 295, "354335"),
                       shape(.ellipse, "Sunrise", 286, 700, 210, 210, "D9DFAE"),
                       text("VOLUME 01     /     ROOM TO BREATHE", 58, 995, 14, "354335", width: 730),
                       text("Less, but\nbetter.", 58, 160, 94, "354335", width: 730, page: 1),
                       text("An invitation to slow down, look closely,\nand find beauty in what remains.", 58, 420, 28, "6B7561", width: 710, page: 1),
                       text("Space is not an absence. It is the beginning of possibility.\n\nA room, a page, a moment: each asks the same question.\nWhat matters enough to stay?\n\nMake room for the things that make you feel something.", 58, 650, 22, "354335", width: 720, page: 1),
                       shape(.rectangle, "Back cover", 0, 100, 840, 910, "354335", page: 2),
                       text("Take\nyour\ntime.", 58, 250, 136, "D9DFAE", width: 740, page: 2)]
    }
    static func landscape(_ d: inout CreativeDocument) {
        d.elements = [shape(.rectangle, "Sky", 0, 0, 1400, 1000, "D4DCCC"),
                      shape(.ellipse, "Sun", 980, 170, 160, 160, "F5E4B9"),
                      shape(.ellipse, "Distant hill", -260, 425, 1400, 1000, "8C9A78"),
                      shape(.ellipse, "Near hill", 490, 550, 1450, 1000, "4A6046"),
                      shape(.ellipse, "Foreground", -180, 765, 1400, 700, "283B2E"),
                      text("SOMEWHERE, SLOWLY.", 65, 75, 20, "3C4A38")]
    }
    static func motion(_ d: inout CreativeDocument) {
        d.elements = [text("A NEW", 70, 130, 115, "D9E6B9"), text("PERSPECTIVE.", 70, 260, 115, "D9E6B9"),
                      text("A STUDY IN MOVEMENT / DEVIN MOTION", 76, 620, 16, "91A786"),
                      shape(.ellipse, "Orbit", 940, 130, 240, 240, "D6A084")]
        d.elements[0].keyframes = [Keyframe(time: 0, x: -800, y: 130, opacity: 0), Keyframe(time: 1, x: 70, y: 130), Keyframe(time: 4, x: 70, y: 130), Keyframe(time: 5, x: 70, y: -200, opacity: 0)]
        d.elements[1].keyframes = [Keyframe(time: 0, x: 1280, y: 260, opacity: 0), Keyframe(time: 1.5, x: 70, y: 260), Keyframe(time: 4, x: 70, y: 260), Keyframe(time: 5, x: -1200, y: 260)]
        d.elements[3].keyframes = [Keyframe(time: 0, x: 940, y: 400, scale: 0.2), Keyframe(time: 2.5, x: 940, y: 100), Keyframe(time: 5, x: 940, y: 400, scale: 0.2)]
    }
    static func frames(_ d: inout CreativeDocument) {
        d.pageCount = 12; d.fps = 12; d.background = "252E26"
        for i in 0..<12 {
            let angle = Double(i) / 12 * .pi * 2
            d.elements.append(shape(.ellipse, "Orbit guide", 170, 170, 460, 460, "354635", page: i))
            d.elements.append(shape(.ellipse, "Center", 200, 200, 400, 400, "252E26", page: i))
            d.elements.append(shape(.ellipse, "Satellite", 350 + cos(angle) * 220, 350 + sin(angle) * 220, 100, 100, "D8E4A7", page: i))
            d.elements.append(text("ORBITAL STUDIES", 60, 60, 22, "D8E4A7", width: 680, page: i))
            d.elements.append(text("FRAME / " + String(format: "%02d", i + 1), 60, 715, 15, "A7B09B", width: 680, page: i))
        }
    }
}
