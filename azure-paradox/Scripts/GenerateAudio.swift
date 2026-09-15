import Foundation

let output = CommandLine.arguments[1]
let rate = 22050
func wave(_ name: String, duration: Double, sample: (Double) -> Double) throws {
  let count = Int(duration * Double(rate))
  var pcm = Data()
  func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
  }
  for index in 0..<count {
    let value = max(-1, min(1, sample(Double(index) / Double(rate))))
    append(Int16(value * 22000), to: &pcm)
  }
  var file = Data("RIFF".utf8)
  append(UInt32(36 + pcm.count), to: &file)
  file.append(Data("WAVEfmt ".utf8))
  append(UInt32(16), to: &file)
  append(UInt16(1), to: &file)
  append(UInt16(1), to: &file)
  append(UInt32(rate), to: &file)
  append(UInt32(rate * 2), to: &file)
  append(UInt16(2), to: &file)
  append(UInt16(16), to: &file)
  file.append(Data("data".utf8))
  append(UInt32(pcm.count), to: &file)
  file.append(pcm)
  try file.write(to: URL(fileURLWithPath: output).appendingPathComponent("\(name).wav"))
}
let melody = [
  74, 77, 81, 84, 81, 77, 76, 72, 74, 77, 79, 81, 86, 84, 81, 79,
  70, 74, 77, 81, 79, 77, 74, 72, 69, 72, 76, 81, 79, 76, 72, 69,
]
let bass = [38, 38, 34, 33]
let beat = 60.0 / 144.0
func frequency(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }
try wave("battle", duration: beat * 64) { t in
  let eighth = Int(t / (beat / 2))
  let noteTime = t.truncatingRemainder(dividingBy: beat / 2)
  let freq = frequency(melody[eighth % melody.count])
  let lead =
    (sin(t * freq * 2 * .pi) + 0.25 * sin(t * freq * 4 * .pi))
    * exp(-noteTime * 9) * 0.23
  let low = sin(t * frequency(bass[Int(t / (beat * 4)) % 4]) * 2 * .pi) * 0.18
  let drumTime = t.truncatingRemainder(dividingBy: beat)
  let kick =
    sin(2 * .pi * (65 * drumTime + 5 * (1 - exp(-drumTime * 35))))
    * exp(-drumTime * 22) * 0.28
  let hat = sin(t * 9167) * sin(t * 12837) * exp(-noteTime * 75) * 0.11
  let chord = sin(t * frequency(62 + [0, 0, -4, -5][Int(t / (beat * 4)) % 4]) * 2 * .pi) * 0.07
  return lead + low + kick + hat + chord
}
try wave("hit", duration: 0.23) { t in
  (sin(t * 810) * sin(t * 6137) * 0.6 + sin(2 * .pi * (140 * t - 150 * t * t)) * 0.5)
    * exp(-t * 21)
}
try wave("swing", duration: 0.25) { t in
  sin(t * 9087) * sin(t * 3291) * sin(min(1, t / 0.25) * .pi) * 0.22
}
try wave("block", duration: 0.3) { t in
  (sin(t * 4500) + sin(t * 6214) * 0.4) * exp(-t * 20) * 0.4
}
try wave("super", duration: 1.2) { t in
  (sin(2 * .pi * (160 * t + 340 * t * t)) * 0.4 + sin(t * 8900) * sin(t * 9912) * 0.15)
    * exp(-t * 2)
}
