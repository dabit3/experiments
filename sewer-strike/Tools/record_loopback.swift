import AVFoundation
import Foundation

struct AudioPacket: Codable {
  let hostTime: UInt64
  let hostSeconds: Double
  let sampleTime: Int64
  let frames: UInt32
  let sampleRate: Double
  let callbackWallTime: Double
}

struct CaptureReport: Codable {
  let records: [AudioPacket]
  let errors: [String]
  let sampleRate: Double
  let channels: UInt32
  let writtenFrames: Int64
  var fileFrames: Int64 = 0
}

final class CaptureSink {
  private let lock = NSLock()
  private let format: AVAudioFormat
  private var file: AVAudioFile?
  private var records: [AudioPacket] = []
  private var errors: [String] = []
  private var writtenFrames: Int64 = 0

  init(url: URL, format: AVAudioFormat) throws {
    self.format = format
    file = try AVAudioFile(forWriting: url, settings: format.settings)
  }

  func append(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
    lock.lock()
    defer { lock.unlock() }
    guard let file else { return }
    do {
      try file.write(from: buffer)
      writtenFrames += Int64(buffer.frameLength)
      records.append(
        AudioPacket(
          hostTime: time.hostTime,
          hostSeconds: AVAudioTime.seconds(forHostTime: time.hostTime),
          sampleTime: time.sampleTime,
          frames: buffer.frameLength,
          sampleRate: time.sampleRate,
          callbackWallTime: Date().timeIntervalSince1970))
    } catch {
      errors.append(String(describing: error))
    }
  }

  func finish() -> CaptureReport {
    lock.lock()
    defer { lock.unlock() }
    file = nil
    return CaptureReport(
      records: records, errors: errors, sampleRate: format.sampleRate,
      channels: format.channelCount, writtenFrames: writtenFrames)
  }
}

guard CommandLine.arguments.count == 3,
  let duration = Double(CommandLine.arguments[2]), duration.isFinite, duration > 0
else {
  fputs("Usage: record-loopback OUTPUT_PREFIX SECONDS\n", stderr)
  exit(1)
}

do {
  let prefix = CommandLine.arguments[1]
  let url = URL(fileURLWithPath: prefix + ".caf")
  let engine = AVAudioEngine()
  let input = engine.inputNode
  let format = input.outputFormat(forBus: 0)
  guard format.sampleRate > 0, format.channelCount > 0 else {
    fputs("No audio input: verify the host endpoint before recording.\n", stderr)
    exit(1)
  }
  let sink = try CaptureSink(url: url, format: format)
  input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
    sink.append(buffer, at: time)
  }
  var tapInstalled = true
  defer {
    engine.stop()
    if tapInstalled { input.removeTap(onBus: 0) }
    _ = sink.finish()
  }
  try engine.start()
  print("READY", format, Date().timeIntervalSince1970)
  fflush(stdout)
  let deadline = Date().addingTimeInterval(duration)
  while Date() < deadline && !FileManager.default.fileExists(atPath: prefix + ".stop") {
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
  }
  engine.stop()
  input.removeTap(onBus: 0)
  tapInstalled = false
  var report = sink.finish()
  report.fileFrames = try AVAudioFile(forReading: url).length
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(report).write(to: URL(fileURLWithPath: prefix + "-timing.json"))
  guard report.errors.isEmpty, report.writtenFrames > 0,
    report.writtenFrames == report.fileFrames
  else {
    fputs("Capture failed: inspect write errors and frame counts in timing JSON.\n", stderr)
    exit(2)
  }
  print("STOP", report.records.count, report.fileFrames)
} catch {
  fputs("Capture failed: \(error)\n", stderr)
  exit(1)
}
