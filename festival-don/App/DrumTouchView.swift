import SwiftUI
import UIKit

struct DrumTouchView: UIViewRepresentable {
    var onHit: (String, String) -> Void

    func makeUIView(context: Context) -> DrumSurface {
        let view = DrumSurface()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.onHit = onHit
        return view
    }

    func updateUIView(_ uiView: DrumSurface, context: Context) { uiView.onHit = onHit }
}

final class DrumSurface: UIView {
    var onHit: ((String, String) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: self)
            for (index, center) in [CGPoint(x: 110, y: 84), CGPoint(x: 350, y: 84)].enumerated() {
                let dx = (point.x - center.x) / 88
                let dy = (point.y - center.y) / 73
                let distance = dx * dx + dy * dy
                guard distance <= 1.2 else { continue }
                let kind = distance < 0.58 ? "don" : "ka"
                onHit?(kind, index == 0 ? "left" : "right")
                break
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let centers = [(110.0, "left"), (350.0, "right")]
        accessibilityElements = centers.flatMap { x, hand in
            [("don", 84.0), ("ka", 20.0)].map { kind, y in
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityLabel = "\(hand.capitalized) \(kind == "don" ? "center DON" : "rim KA")"
                element.accessibilityIdentifier = "\(hand)-\(kind)"
                element.accessibilityTraits = .button
                element.accessibilityFrameInContainerSpace = CGRect(x: x - 22, y: y - 12, width: 44, height: 24)
                return element
            }
        }
    }
}
