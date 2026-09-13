import SpriteKit
import UIKit

enum PixelArt {
  static let ink = UIColor(hex: 0x14283d)
  static let blue = UIColor(hex: 0x48c8ff)
  static let gold = UIColor(hex: 0xffce5a)
  static func team(_ team: Int) -> UIColor { team == 0 ? blue : gold }

  static func texture(rows: [String], palette: [Character: UIColor], scale: CGFloat = 1)
    -> SKTexture
  {
    let width = rows.map(\.count).max() ?? 1
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(
      size: CGSize(width: CGFloat(width) * scale, height: CGFloat(rows.count) * scale),
      format: format
    ).image { context in
      for (y, row) in rows.enumerated() {
        for (x, pixel) in row.enumerated() {
          guard let color = palette[pixel] else { continue }
          context.cgContext.setFillColor(color.cgColor)
          context.cgContext.fill(
            CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: scale, height: scale))
        }
      }
    }
    let texture = SKTexture(image: image)
    texture.filteringMode = .nearest
    return texture
  }

  static func insect(team: Int, role: String, frame: Int) -> SKTexture {
    let crown = role == "queen"
    let wing = role != "worker"
    var rows = [
      "........................",
      "........................",
      "........o....o..........",
      ".........o..o...........",
      ".........oooo...........",
      "........otttto..........",
      ".......otttttto.........",
      ".......otWotWoo.........",
      ".......otWotWoo.........",
      "........otttto..........",
      ".........oooo...........",
      "........ottttto.........",
      ".......otLLLLtto........",
      "......oottttttoo........",
      "......ootDDDDtoo........",
      ".......otttttto.........",
      "........oDDDDoo.........",
      ".........oooo...........",
      ".........o..o...........",
      "........oo..oo..........",
      "........................",
    ]
    if crown {
      rows[0] = ".......G...G...G........"
      rows[1] = ".......GG.GGG.GG........"
      rows[2] = "........GGGGGGG........."
      rows[3] = "........oRRRRo.........."
    }
    if wing {
      rows[7] = frame == 0 ? "..WW...otWotWoo...WW...." : ".......otWotWoo........."
      rows[8] = frame == 0 ? "..WWW..otWotWoo..WWW...." : "WW.....otWotWoo.....WW.."
      rows[9] = frame == 0 ? "...WWW..otttto..WWW....." : ".WWWW...otttto..WWWWW..."
      rows[10] = frame == 0 ? "....WWW..oooo..WWW......" : "..WWWWW..oooo..WWWWWW..."
      rows[12] = ".......otLLLLtto....W..."
      rows[13] = "......oottttttoo...WW..."
      rows[14] = "......ootDDDDtoo..WW...."
      rows[15] = ".......otttttto.GGW....."
    }
    if frame == 1 {
      rows[18] = "........o....o.........."
      rows[19] = ".......oo.....oo........"
    }
    return texture(
      rows: rows,
      palette: [
        "o": ink, "t": team == 0 ? blue : gold, "L": UIColor(hex: 0xffecb4),
        "D": UIColor(hex: team == 0 ? 0x2571b5 : 0xb56c28),
        "W": UIColor(hex: 0xe8f9ff), "G": gold, "R": UIColor(hex: 0xeb6397),
      ])
  }

  static func snail(frame: Int) -> SKTexture {
    let rows = [
      "..........................................",
      "...........ooooooo........................",
      ".........ooGGGGGGGoo......................",
      "........oGGAAAAAAAGGo.....................",
      ".......oGGAoooooAAGGo.....................",
      "......oGGAooGGGooAAGGo....................",
      "......oGGAoGGAAGoAAGGo....................",
      "......oGGAoGAoAGoAAGGo....................",
      "......oGGAooAAAGoAAGGo...........o....o...",
      "......oGGAAoooooAAAGGo...........o....o...",
      ".......oGGAAAAAAAAGGo............o..o....",
      "........ooGGGGGGGoo..............oooo....",
      ".....ooooooGGGGGoooooooooooooooooLLLLo...",
      "....oLLLLLLoooooLLLLLLLLLLLLLLLLLLLLLLo..",
      "...oLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLo..",
      "...oDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDo...",
      frame == 0
        ? "....oooo..oooo..oooo..oooo..oooo..oooo...."
        : ".....oooo..oooo..oooo..oooo..oooo..oooo...",
    ]
    return texture(
      rows: rows,
      palette: [
        "o": ink, "G": UIColor(hex: 0xdb9461), "A": UIColor(hex: 0x9b5a59),
        "L": UIColor(hex: 0xbbdb86), "D": UIColor(hex: 0x78a879),
      ])
  }

  static func berry() -> SKTexture {
    texture(
      rows: [
        "...gg...", "..gG....", "..oooo..", ".oppppo.",
        "opWWpppo", "oppppPpo", ".opPPPo.", "..oooo..",
      ],
      palette: [
        "g": UIColor(hex: 0x397c61), "G": UIColor(hex: 0xa0cf79), "o": ink,
        "p": UIColor(hex: 0xda44d5), "P": UIColor(hex: 0x88288e), "W": UIColor(hex: 0xff99ef),
      ])
  }

  static func sky() -> SKTexture {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: 480, height: 270), format: format).image
    { ctx in
      for y in 0..<270 {
        UIColor(
          red: 0.10 + Double(y) / 1400, green: 0.55 + Double(y) / 1500,
          blue: 0.74 + Double(y) / 2000, alpha: 1
        ).setFill()
        ctx.fill(CGRect(x: 0, y: y, width: 480, height: 1))
      }
      for i in 0..<18 {
        let x = (i * 113 + 7) % 490 - 25
        let y = (i * 67 + 13) % 240
        UIColor(hex: i % 2 == 0 ? 0x72bada : 0x46a2ca).withAlphaComponent(0.6).setFill()
        for j in 0..<7 {
          let dx = j * 8
          let dy = [8, 3, 0, -5, 0, 5, 9][j]
          ctx.fill(CGRect(x: x + dx, y: y + dy, width: 20, height: 7))
          ctx.fill(CGRect(x: x + dx + 3, y: y + dy - 3, width: 13, height: 13))
        }
      }
    }
    let result = SKTexture(image: image)
    result.filteringMode = .nearest
    return result
  }
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: 1)
  }
}
