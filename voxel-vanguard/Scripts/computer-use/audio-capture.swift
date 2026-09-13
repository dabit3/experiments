import AVFoundation
import Foundation

struct BufferEvidence: Encodable {
  let hostSeconds: Double
  let callbackWall: Double
  let sampleTime: Int64
  let offsetFrames: Int64
  let frames: UInt32
  let sampleRate: Double
  let channels: UInt32
  let peak: Double
  let rms: Double
}

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let seconds = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2])! : 900
let engine = AVAudioEngine()
let input = engine.inputNode
let format = input.outputFormat(forBus: 0)
var file: AVAudioFile? = try AVAudioFile(
  forWriting: root.appendingPathComponent("loopback.caf"), settings: format.settings)
let metadata = root.appendingPathComponent("audio-buffers.jsonl")
FileManager.default.createFile(atPath: metadata.path, contents: nil)
let log = try FileHandle(forWritingTo: metadata)
let encoder = JSONEncoder()
var totalFrames: Int64 = 0
input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
  do {
    try file!.write(from: buffer)
    var sum = 0.0
    var peak = 0.0
    if let channels = buffer.floatChannelData {
      for channel in 0..<Int(buffer.format.channelCount) {
        for index in 0..<Int(buffer.frameLength) {
          let value = Double(channels[channel][index])
          sum += value * value
          peak = max(peak, abs(value))
        }
      }
    }
    let row = BufferEvidence(
      hostSeconds: AVAudioTime.seconds(forHostTime: time.hostTime),
      callbackWall: Date().timeIntervalSince1970,
      sampleTime: time.sampleTime, offsetFrames: totalFrames,
      frames: buffer.frameLength, sampleRate: buffer.format.sampleRate,
      channels: buffer.format.channelCount, peak: peak,
      rms: sqrt(sum / Double(buffer.frameLength * buffer.format.channelCount)))
    try log.write(contentsOf: encoder.encode(row))
    try log.write(contentsOf: Data([10]))
    totalFrames += Int64(buffer.frameLength)
  } catch {
    fputs("CAPTURE ERROR: \(error)\n", stderr)
  }
}
try engine.start()
print("CAPTURING \(format) wall=\(Date().timeIntervalSince1970)")
fflush(stdout)
let end = Date().addingTimeInterval(seconds)
while Date() < end
  && !FileManager.default.fileExists(atPath: root.appendingPathComponent("AUDIO_STOP").path)
{
  RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}
input.removeTap(onBus: 0)
engine.stop()
file = nil
try log.close()
print("STOPPED frames=\(totalFrames) wall=\(Date().timeIntervalSince1970)")
