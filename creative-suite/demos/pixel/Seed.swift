// Explicit STARTING INPUT, not a recording or simulated Pixel edit.
// Deterministic procedural landscape; all cover typography is added live in Pixel.
import AppKit
let width = 900, height = 1100
var bytes = [UInt8](repeating:255,count:width*height*4)
func mix(_ a:[Double],_ b:[Double],_ t:Double)->[Double] { zip(a,b).map { $0+($1-$0)*t } }
for y in 0..<height {
    for x in 0..<width {
        let px = Double(x), py = Double(y)
        var c:[Double] = [238,232,215]
        if y > 350 && y < 975 && x > 50 && x < 850 {
            let t = (py-350)/625
            c = mix([224,153,111],[72,92,107],t)
            let sun = hypot(px-609,py-533)
            if sun < 132 { c = mix([254,215,130],[239,152,99],(py-400)/266) }
            let ridge1 = 685 + 46*sin(px/154) + 25*sin(px/83)
            let ridge2 = 792 + 70*sin(px/232+1.7)
            let ridge3 = 916 + 49*sin(px/174+0.6)
            if py > ridge1 { c = mix([135,85,75],[65,68,82],(py-ridge1)/350) }
            if py > ridge2 { c = mix([56,71,81],[28,49,62],(py-ridge2)/300) }
            if py > ridge3 { c = [23,43,54] }
            let noise = Double((x*73+y*131+x*y*17)%101)/101-0.5
            c = c.map { $0+noise*7 }
        }
        let i=(y*width+x)*4
        for k in 0..<3 { bytes[i+k]=UInt8(max(0,min(255,c[k]))) }
    }
}
let provider=CGDataProvider(data:Data(bytes) as CFData)!
let image=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
let data=NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])!
try data.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
print("Starting input only: \(width)×\(height) landscape; no final text or paint accents.")
