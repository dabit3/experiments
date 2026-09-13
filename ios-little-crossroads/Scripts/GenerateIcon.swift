import AppKit

let size = 1024
guard let canvas = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)
else { fatalError("Could not create icon canvas") }
canvas.interpolationQuality = .none
canvas.setShouldAntialias(false)

func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: 1)
}

let sky = rgb(0.36, 0.58, 0.99)
let dark = rgb(0.05, 0.05, 0.09)
let yellow = rgb(0.99, 0.88, 0.10)
let light = rgb(0.99, 0.92, 0.37)
let beak = rgb(0.98, 0.53, 0.09)
let grass = rgb(0.43, 0.78, 0.16)
let grassDeep = rgb(0.33, 0.69, 0.13)
let road = rgb(0.36, 0.36, 0.38)
let white = rgb(0.99, 0.99, 0.99)

// The icon is a 40x40 pixel scene scaled up without smoothing.
let grid = 40
let unit = CGFloat(size) / CGFloat(grid)
func pixel(_ x: Int, _ y: Int, _ color: CGColor, _ width: Int = 1, _ height: Int = 1) {
    canvas.setFillColor(color)
    canvas.fill(CGRect(
        x: CGFloat(x) * unit, y: CGFloat(grid - y - height) * unit,
        width: CGFloat(width) * unit, height: CGFloat(height) * unit
    ))
}

pixel(0, 0, sky, grid, grid)
pixel(0, 29, grassDeep, grid, 2)
pixel(0, 31, grass, grid, 3)
pixel(0, 34, road, grid, 6)
pixel(0, 34, white, grid, 1)
for x in stride(from: 2, to: grid, by: 7) {
    pixel(x, 37, white, 3, 1)
}

for (x, y) in [(3, 6), (29, 3)] {
    pixel(x, y, white, 6, 2)
    pixel(x + 1, y - 1, white, 4, 1)
}

/// The same duck sprite that appears in the wardrobe, drawn at 16x16 and doubled.
let duck = [
    "................",
    "......kkkk......",
    ".....kyyyyk.....",
    "....kyywyyyk....",
    "....kyykyyykooo.",
    "....kyyyyyyykook",
    "....kyyyyyyyyko.",
    ".....kyyyyyyk...",
    "..kkkkkyyyyyk...",
    ".kyyyyyyyyyyyk..",
    "kyyyyyyyyyyyyyk.",
    "kyllllyyyyyyyyk.",
    "kylllllyyyyyyk..",
    ".kyllllyyyyyyk..",
    "..kkkkkkkkkkk...",
    "....ook..ook....",
]
for (rowIndex, row) in duck.enumerated() {
    for (column, character) in row.enumerated() {
        let color: CGColor? = switch character {
        case "k": dark
        case "y": yellow
        case "l": light
        case "w": white
        case "o": beak
        default: nil
        }
        if let color {
            pixel(column * 2 + 4, rowIndex * 2 + 1, color, 2, 2)
        }
    }
}

// Chunky console-style frame.
pixel(0, 0, dark, grid, 1)
pixel(0, grid - 1, dark, grid, 1)
pixel(0, 0, dark, 1, grid)
pixel(grid - 1, 0, dark, 1, grid)

guard let image = canvas.makeImage() else { fatalError("Could not render icon") }
let bitmap = NSBitmapImageRep(cgImage: image)
guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try data.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
