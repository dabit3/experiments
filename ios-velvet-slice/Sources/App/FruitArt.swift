import SpriteKit
import UIKit

enum FruitKind: Int, CaseIterable {
    case citrus, kiwi, dragon

    var juice: UIColor {
        switch self {
        case .citrus: UIColor(red: 1, green: 0.61, blue: 0.18, alpha: 1)
        case .kiwi: UIColor(red: 0.68, green: 0.9, blue: 0.31, alpha: 1)
        case .dragon: UIColor(red: 1, green: 0.29, blue: 0.55, alpha: 1)
        }
    }
}

@MainActor
enum FruitArt {
    static let images = FruitKind.allCases.map { draw($0) }
    static let bomb = drawBomb()
    static let splatter = SKTexture(image: drawSplatter())
    static let vignette = SKTexture(image: drawVignette())

    static func image(_ kind: FruitKind) -> UIImage {
        images[kind.rawValue]
    }

    static func draw(_ kind: FruitKind) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: 220, height: 240), format: format).image { renderer in
            let c = renderer.cgContext
            c.translateBy(x: 110, y: 130)
            c.setShadow(offset: CGSize(width: 0, height: 8), blur: 14, color: UIColor.black.withAlphaComponent(0.45).cgColor)
            let outer = CGRect(x: -89, y: -91, width: 178, height: 180)
            c.setFillColor((kind == .kiwi ? UIColor(red: 0.4, green: 0.27, blue: 0.1, alpha: 1) : kind.juice).cgColor)
            c.fillEllipse(in: outer)
            c.setShadow(offset: .zero, blur: 0)
            if kind == .kiwi {
                for i in 0 ..< 90 {
                    let angle = CGFloat(i) * 2.39996
                    let r: CGFloat = 84 + CGFloat(i % 4)
                    c.setFillColor(UIColor(red: 0.55, green: 0.4, blue: 0.2, alpha: 0.9).cgColor)
                    c.fillEllipse(in: CGRect(x: cos(angle) * r - 1.5, y: sin(angle) * r - 1, width: 3, height: 2))
                }
            }
            if kind == .dragon {
                for i in 0 ..< 9 {
                    let angle = CGFloat(i) * .pi * 2 / 9
                    c.saveGState()
                    c.rotate(by: angle)
                    let petal = UIBezierPath()
                    petal.move(to: CGPoint(x: 60, y: -28))
                    petal.addQuadCurve(to: CGPoint(x: 108, y: -5), controlPoint: CGPoint(x: 97, y: -38))
                    petal.addQuadCurve(to: CGPoint(x: 71, y: 24), controlPoint: CGPoint(x: 87, y: 25))
                    UIColor(red: 0.88, green: 0.14, blue: 0.44, alpha: 1).setFill()
                    petal.fill()
                    c.restoreGState()
                }
            }
            c.setFillColor(UIColor(red: 1, green: 0.92, blue: 0.72, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: -81, y: -84, width: 162, height: 164))
            c.saveGState()
            c.addEllipse(in: CGRect(x: -76, y: -79, width: 152, height: 154))
            c.clip()
            let colors: [CGColor] = switch kind {
            case .citrus:
                [UIColor(red: 1, green: 0.8, blue: 0.27, alpha: 1).cgColor, UIColor(red: 0.96, green: 0.34, blue: 0.05, alpha: 1).cgColor]
            case .kiwi:
                [UIColor(red: 0.91, green: 0.97, blue: 0.42, alpha: 1).cgColor, UIColor(red: 0.24, green: 0.63, blue: 0.15, alpha: 1).cgColor]
            case .dragon:
                [UIColor(red: 1, green: 0.97, blue: 0.9, alpha: 1).cgColor, UIColor(red: 0.97, green: 0.65, blue: 0.76, alpha: 1).cgColor]
            }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                c.drawRadialGradient(gradient, startCenter: CGPoint(x: -15, y: -22), startRadius: 1, endCenter: .zero, endRadius: 90, options: .drawsAfterEndLocation)
            }
            if kind == .citrus {
                for i in 0 ..< 10 {
                    c.saveGState()
                    c.rotate(by: CGFloat(i) * .pi / 5)
                    c.setStrokeColor(UIColor(red: 1, green: 0.93, blue: 0.67, alpha: 0.95).cgColor)
                    c.setLineWidth(3)
                    c.move(to: CGPoint(x: 4, y: 0))
                    c.addLine(to: CGPoint(x: 80, y: 0))
                    c.strokePath()
                    for j in 0 ..< 5 {
                        c.setFillColor(UIColor.white.withAlphaComponent(0.16).cgColor)
                        c.fillEllipse(in: CGRect(x: 20 + j * 9, y: 7 + j % 2 * 6, width: 12, height: 4))
                    }
                    c.restoreGState()
                }
                c.setFillColor(UIColor(red: 1, green: 0.95, blue: 0.73, alpha: 1).cgColor)
                c.fillEllipse(in: CGRect(x: -7, y: -7, width: 14, height: 14))
            } else if kind == .kiwi {
                for i in 0 ..< 38 {
                    c.saveGState()
                    c.rotate(by: CGFloat(i) * .pi * 2 / 38)
                    c.setStrokeColor(UIColor.white.withAlphaComponent(0.24).cgColor)
                    c.setLineWidth(1.2)
                    c.move(to: CGPoint(x: 12, y: 0))
                    c.addLine(to: CGPoint(x: 75, y: 0))
                    c.strokePath()
                    c.setFillColor(UIColor(red: 0.13, green: 0.19, blue: 0.08, alpha: 1).cgColor)
                    c.fillEllipse(in: CGRect(x: CGFloat(27 + i % 3 * 4), y: 0, width: 7, height: 3.5))
                    c.restoreGState()
                }
                c.setFillColor(UIColor(red: 0.96, green: 0.98, blue: 0.73, alpha: 1).cgColor)
                c.fillEllipse(in: CGRect(x: -15, y: -20, width: 30, height: 40))
            } else {
                for i in 0 ..< 75 {
                    let angle = CGFloat(i) * 2.39996
                    let r = sqrt(CGFloat(i) / 75) * 71
                    c.saveGState()
                    c.translateBy(x: cos(angle) * r, y: sin(angle) * r)
                    c.rotate(by: angle)
                    c.setFillColor(UIColor(red: 0.21, green: 0.11, blue: 0.2, alpha: 0.85).cgColor)
                    c.fillEllipse(in: CGRect(x: -1.3, y: -2.3, width: 2.6, height: 4.6))
                    c.restoreGState()
                }
            }
            c.restoreGState()
            c.saveGState()
            c.addEllipse(in: CGRect(x: -76, y: -79, width: 152, height: 154))
            c.clip()
            let shading: [CGColor] = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.22).cgColor]
            if let rim = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: shading as CFArray, locations: [0.62, 1]) {
                c.drawRadialGradient(rim, startCenter: CGPoint(x: -10, y: -14), startRadius: 0, endCenter: .zero, endRadius: 82, options: .drawsAfterEndLocation)
            }
            let gleam: [CGColor] = [UIColor.white.withAlphaComponent(0.42).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            if let highlight = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gleam as CFArray, locations: [0, 1]) {
                c.drawRadialGradient(highlight, startCenter: CGPoint(x: -34, y: -42), startRadius: 0, endCenter: CGPoint(x: -30, y: -38), endRadius: 46, options: [])
            }
            c.restoreGState()
            c.setStrokeColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            c.setLineWidth(2.4)
            c.setLineCap(.round)
            c.addArc(center: CGPoint(x: 0, y: -2), radius: 84, startAngle: .pi * 1.12, endAngle: .pi * 1.68, clockwise: false)
            c.strokePath()
            if kind != .dragon {
                let leaf = UIBezierPath()
                leaf.move(to: CGPoint(x: 0, y: -85))
                leaf.addCurve(to: CGPoint(x: 53, y: -111), controlPoint1: CGPoint(x: 3, y: -116), controlPoint2: CGPoint(x: 35, y: -126))
                leaf.addCurve(to: CGPoint(x: 0, y: -85), controlPoint1: CGPoint(x: 38, y: -87), controlPoint2: CGPoint(x: 17, y: -76))
                UIColor(red: 0.29, green: 0.61, blue: 0.29, alpha: 1).setFill()
                leaf.fill()
                c.setStrokeColor(UIColor(red: 0.72, green: 0.88, blue: 0.37, alpha: 0.7).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 0, y: -85))
                c.addLine(to: CGPoint(x: 46, y: -109))
                c.strokePath()
            }
        }
    }

    static func drawSplatter() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 300, height: 140)).image { renderer in
            let c = renderer.cgContext
            c.translateBy(x: 150, y: 70)
            let fade: [CGColor] = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fade as CFArray, locations: [0.15, 1]) else { return }
            let blobs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(0, 0, 70, 24), (-58, 6, 32, 14), (54, -7, 38, 15), (-96, -4, 16, 8), (98, 9, 18, 9), (22, 17, 20, 9), (-30, -18, 18, 8)]
            for (x, y, w, h) in blobs {
                c.saveGState()
                c.translateBy(x: x, y: y)
                c.scaleBy(x: w / 24, y: h / 24)
                c.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 24, options: [])
                c.restoreGState()
            }
        }
    }

    static func drawVignette() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256)).image { renderer in
            let c = renderer.cgContext
            let fade: [CGColor] = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.35).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fade as CFArray, locations: [0, 0.45, 1]) else { return }
            c.drawRadialGradient(gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 0, endCenter: CGPoint(x: 128, y: 128), endRadius: 128, options: [])
        }
    }

    static func drawBomb() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 220, height: 240)).image { renderer in
            let c = renderer.cgContext
            c.translateBy(x: 110, y: 130)
            c.setShadow(offset: CGSize(width: 0, height: 8), blur: 14, color: UIColor.black.cgColor)
            c.setFillColor(UIColor(red: 0.19, green: 0.23, blue: 0.3, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: -80, y: -80, width: 160, height: 160))
            c.setShadow(offset: .zero, blur: 0)
            c.setStrokeColor(UIColor(red: 1, green: 0.43, blue: 0.36, alpha: 1).cgColor)
            c.setLineWidth(4)
            c.strokeEllipse(in: CGRect(x: -78, y: -78, width: 156, height: 156))
            c.setFillColor(UIColor(red: 0.32, green: 0.38, blue: 0.44, alpha: 1).cgColor)
            c.fill(CGRect(x: -15, y: -95, width: 30, height: 22))
            c.setLineWidth(5)
            c.move(to: CGPoint(x: 0, y: -95))
            c.addQuadCurve(to: CGPoint(x: 27, y: -117), control: CGPoint(x: -8, y: -125))
            c.strokePath()
            c.setFillColor(UIColor(red: 1, green: 0.79, blue: 0.34, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: 21, y: -125, width: 13, height: 13))
            c.setLineWidth(8)
            c.setLineCap(.round)
            c.move(to: CGPoint(x: -21, y: -21))
            c.addLine(to: CGPoint(x: 21, y: 21))
            c.move(to: CGPoint(x: 21, y: -21))
            c.addLine(to: CGPoint(x: -21, y: 21))
            c.strokePath()
            c.setStrokeColor(UIColor.white.withAlphaComponent(0.22).cgColor)
            c.setLineWidth(3)
            c.addArc(center: .zero, radius: 63, startAngle: .pi * 1.1, endAngle: .pi * 1.55, clockwise: false)
            c.strokePath()
        }
    }
}
