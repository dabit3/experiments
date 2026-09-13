import AVFoundation
import Darwin
import Foundation

struct BufferClock: Codable {
  let sampleTime: Int64
  let hostTime: UInt64
  let frames: UInt32
  let callbackHostTime: UInt64
  let sampleTimeValid: Bool
  let hostTimeValid: Bool
}

struct Anchor: Codable {
  let beforeEpoch: Double
  let hostTime: UInt64
  let hostSeconds: Double
  let afterEpoch: Double
}

struct Evidence: Codable {
  let sampleRate: Double
  let channels: UInt32
  let pid: Int32
  let initialAnchor: Anchor
  let finalAnchor: Anchor
  let clocks: [BufferClock]
  let errors: [String]
}

func anchor() -> Anchor {
  let before = Date().timeIntervalSince1970
  let host = mach_absolute_time()
  return Anchor(
    beforeEpoch: before, hostTime: host,
    hostSeconds: AVAudioTime.seconds(forHostTime: host),
    afterEpoch: Date().timeIntervalSince1970)
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

let usage = "Usage: CaptureAudio <new-output-prefix> [positive-duration-seconds]"
let arguments = CommandLine.arguments
if arguments.count == 2 && arguments[1] == "--help" {
  print(usage)
  exit(0)
}
guard (2...3).contains(arguments.count), !arguments[1].isEmpty else {
  fail(usage)
}
let duration = arguments.count == 3 ? Double(arguments[2]) : 300
guard let seconds = duration, seconds.isFinite, seconds > 0 else {
  fail(usage)
}
let prefix = arguments[1]
guard
  !FileManager.default.fileExists(atPath: prefix + ".caf"),
  !FileManager.default.fileExists(atPath: prefix + ".callbacks.json")
else {
  fail("Choose a new output prefix; existing recordings are not overwritten.")
}

let engine = AVAudioEngine()
let input = engine.inputNode
let format = input.outputFormat(forBus: 0)
var file: AVAudioFile? = try AVAudioFile(
  forWriting: URL(fileURLWithPath: prefix + ".caf"),
  settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
let initialAnchor = anchor()
var clocks = [BufferClock]()
clocks.reserveCapacity(50_000)
var failures = [String]()
let lock = NSLock()

input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
  let arrival = mach_absolute_time()
  lock.lock()
  clocks.append(
    BufferClock(
      sampleTime: time.sampleTime, hostTime: time.hostTime,
      frames: buffer.frameLength, callbackHostTime: arrival,
      sampleTimeValid: time.isSampleTimeValid, hostTimeValid: time.isHostTimeValid))
  if let file {
    do { try file.write(from: buffer) } catch { failures.append(String(describing: error)) }
  } else {
    failures.append("Audio writer was closed before the input tap stopped.")
  }
  lock.unlock()
}

var stopped = false
func finish() {
  guard !stopped else { return }
  stopped = true
  engine.stop()
  input.removeTap(onBus: 0)
  let finalAnchor = anchor()
  lock.lock()
  let snapshot = clocks
  let errors = failures
  file = nil
  lock.unlock()
  let evidence = Evidence(
    sampleRate: format.sampleRate, channels: format.channelCount,
    pid: getpid(), initialAnchor: initialAnchor, finalAnchor: finalAnchor,
    clocks: snapshot, errors: errors)
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  do {
    try encoder.encode(evidence).write(to: URL(fileURLWithPath: prefix + ".callbacks.json"))
  } catch {
    fail("Could not save callback evidence: \(error)")
  }
  print("NATIVE_AUDIO_STOPPED buffers=\(snapshot.count) errors=\(errors.count)")
  fflush(stdout)
  exit(errors.isEmpty ? 0 : 1)
}

signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
let terminate = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
interrupt.setEventHandler { finish() }
interrupt.resume()
terminate.setEventHandler { finish() }
terminate.resume()
try engine.start()
print(
  "NATIVE_AUDIO_READY pid=\(getpid()) rate=\(format.sampleRate) channels=\(format.channelCount)")
fflush(stdout)
DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { finish() }
RunLoop.main.run()
