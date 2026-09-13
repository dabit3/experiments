import AVFoundation
import Darwin
import Foundation

func host() -> Double {
  var timebase = mach_timebase_info_data_t()
  mach_timebase_info(&timebase)
  return Double(mach_absolute_time()) * Double(timebase.numer) / Double(timebase.denom) / 1e9
}

guard CommandLine.arguments.count == 3,
  let duration = Double(CommandLine.arguments[2]), duration.isFinite, duration > 0
else {
  fatalError("Usage: native-audio-capture OUTPUT_PREFIX MAX_SECONDS")
}
let prefix = CommandLine.arguments[1]
let suffixes = [".wav", "-packets.jsonl", "-metadata.json", ".stop"]
guard !suffixes.contains(where: { FileManager.default.fileExists(atPath: prefix + $0) }) else {
  fatalError("Use a fresh output prefix; existing evidence will not be overwritten")
}
let start = host()
let session = AVCaptureSession()
let queue = DispatchQueue(label: "audio-evidence", qos: .userInteractive)

struct CaptureMetadata: Encodable {
  let spawnHost: Double
  let stopHost: Double
  let firstPTS: Double
  let lastPTS: Double
  let endPTS: Double
  let frames: Int64
  let packets: Int
  let gapCount: Int
  let gapTotal: Double
  let maxGap: Double
  let device: String
  let format: String
}

final class Receiver: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
  var file: AVAudioFile?
  let log: FileHandle
  var frames: Int64 = 0
  var packets = 0
  var first = 0.0
  var last = 0.0
  var end = 0.0
  var gapCount = 0
  var gapTotal = 0.0
  var maxGap = 0.0

  override init() {
    guard FileManager.default.createFile(atPath: prefix + "-packets.jsonl", contents: nil),
      let handle = FileHandle(forWritingAtPath: prefix + "-packets.jsonl")
    else {
      fatalError("Cannot open capture log; output directory must already exist")
    }
    log = handle
    super.init()
  }

  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    do {
      let pts = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
      let count = CMSampleBufferGetNumSamples(sampleBuffer)
      guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else {
        fatalError("Missing native audio format")
      }
      let format = AVAudioFormat(cmAudioFormatDescription: description)
      guard
        let buffer = AVAudioPCMBuffer(
          pcmFormat: format, frameCapacity: AVAudioFrameCount(count))
      else {
        fatalError("Cannot allocate native PCM buffer")
      }
      buffer.frameLength = AVAudioFrameCount(count)
      let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
        sampleBuffer, at: 0, frameCount: Int32(count), into: buffer.mutableAudioBufferList)
      guard status == noErr else { fatalError("PCM copy failed: \(status)") }
      if file == nil {
        file = try AVAudioFile(
          forWriting: URL(fileURLWithPath: prefix + ".wav"),
          settings: format.settings, commonFormat: format.commonFormat,
          interleaved: format.isInterleaved)
        first = pts
        print(
          "READY host=\(host()) firstPTS=\(pts) sampleRate=\(format.sampleRate) channels=\(format.channelCount)"
        )
        fflush(stdout)
      }
      let gap = packets == 0 ? 0 : pts - end
      if gap > 0.001 {
        gapCount += 1
        gapTotal += gap
        maxGap = max(maxGap, gap)
      }
      let row =
        "{\"pts\":\(pts),\"arrivalHost\":\(host()),\"frames\":\(count),\"offset\":\(frames),\"gap\":\(gap)}\n"
      log.write(Data(row.utf8))
      guard let file else { fatalError("Audio file is unavailable") }
      try file.write(from: buffer)
      frames += Int64(count)
      packets += 1
      last = pts
      end = pts + Double(count) / format.sampleRate
    } catch {
      fatalError("Audio capture: \(error)")
    }
  }

  func finish() {
    file = nil
    log.closeFile()
    guard packets > 0 else { fatalError("No audio callbacks received") }
    let result = CaptureMetadata(
      spawnHost: start, stopHost: host(), firstPTS: first, lastPTS: last, endPTS: end,
      frames: frames, packets: packets, gapCount: gapCount, gapTotal: gapTotal,
      maxGap: maxGap, device: "BlackHole 2ch", format: "Native PCM; no inserted samples")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
      try encoder.encode(result).write(to: URL(fileURLWithPath: prefix + "-metadata.json"))
    } catch {
      fatalError("Capture metadata: \(error)")
    }
  }
}

let receiver = Receiver()
guard let device = AVCaptureDevice.default(for: .audio),
  device.localizedName == "BlackHole 2ch"
else {
  fatalError("BlackHole 2ch must be the default audio input")
}
let input = try AVCaptureDeviceInput(device: device)
guard session.canAddInput(input) else { fatalError("Cannot add audio input") }
session.addInput(input)
let output = AVCaptureAudioDataOutput()
output.setSampleBufferDelegate(receiver, queue: queue)
guard session.canAddOutput(output) else { fatalError("Cannot add audio output") }
session.addOutput(output)
session.startRunning()
let timer = DispatchSource.makeTimerSource(queue: .main)
timer.schedule(deadline: .now() + 0.1, repeating: 0.1)
timer.setEventHandler {
  if host() - start >= duration || FileManager.default.fileExists(atPath: prefix + ".stop") {
    session.stopRunning()
    queue.sync { receiver.finish() }
    exit(0)
  }
}
timer.resume()
RunLoop.main.run()
