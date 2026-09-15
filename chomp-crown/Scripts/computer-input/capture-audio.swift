import AVFoundation
import Foundation

struct AudioBufferRecord: Encodable {
  let hostSeconds: Double
  let sampleTime: AVAudioFramePosition
  let frames: AVAudioFrameCount
  let sampleRate: Double
  let hostValid: Bool
  let sampleValid: Bool
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]

// Capture actual default-input loopback only. No generated or reconstructed audio.
guard CommandLine.arguments.count == 3,
  let duration = Double(CommandLine.arguments[2]), duration.isFinite, duration > 0
else {
  fputs("Usage: capture-audio OUTPUT_PREFIX POSITIVE_DURATION_SECONDS\n", stderr)
  exit(2)
}
let prefix = CommandLine.arguments[1]
let engine = AVAudioEngine()
let input = engine.inputNode
let format = input.outputFormat(forBus: 0)
let file = try AVAudioFile(
  forWriting: URL(fileURLWithPath: prefix + ".caf"), settings: format.settings)
FileManager.default.createFile(atPath: prefix + "-buffers.jsonl", contents: nil)
let log = try FileHandle(forWritingTo: URL(fileURLWithPath: prefix + "-buffers.jsonl"))
input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, when in
  do {
    try file.write(from: buffer)
    let record = AudioBufferRecord(
      hostSeconds: AVAudioTime.seconds(forHostTime: when.hostTime),
      sampleTime: when.sampleTime, frames: buffer.frameLength,
      sampleRate: buffer.format.sampleRate,
      hostValid: when.isHostTimeValid, sampleValid: when.isSampleTimeValid)
    var data = try encoder.encode(record)
    data.append(10)
    log.write(data)
  } catch { fputs("CAPTURE ERROR: \(error)\n", stderr) }
}
try engine.start()
print("CAPTURE READY \(format) wallUnix=\(Date().timeIntervalSince1970)")
fflush(stdout)
RunLoop.current.run(until: Date().addingTimeInterval(duration))
engine.stop()
input.removeTap(onBus: 0)
try log.close()
print("CAPTURE STOPPED")
