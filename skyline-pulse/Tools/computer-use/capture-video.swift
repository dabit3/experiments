import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia
import Darwin

final class VideoSink: NSObject, SCStreamOutput {
 let writer: AVAssetWriter
 let input: AVAssetWriterInput
 let adaptor: AVAssetWriterInputPixelBufferAdaptor
 let log: FileHandle
 var first: CMTime?
 var last: CMTime?
 var count = 0
 var skipped = 0
 init(prefix: String, width: Int, height: Int) throws {
  writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: prefix + ".mov"), fileType: .mov)
  input = AVAssetWriterInput(mediaType: .video, outputSettings: [
   AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height])
  input.expectsMediaDataInRealTime = true
  adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
   sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
     kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
  writer.add(input)
  FileManager.default.createFile(atPath: prefix + "-frames.jsonl", contents: nil)
  log = try FileHandle(forWritingTo: URL(fileURLWithPath: prefix + "-frames.jsonl"))
  super.init()
 }
 func emit(_ record: [String:Any]) {
  var data = try! JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
  data.append(10); log.write(data)
 }
 func anchor(_ label: String) {
  let before = AVAudioTime.seconds(forHostTime: mach_absolute_time())
  let cm = CMClockGetTime(CMClockGetHostTimeClock()).seconds
  let after = AVAudioTime.seconds(forHostTime: mach_absolute_time())
  emit(["type":"anchor","label":label,"machBefore":before,"cmHostSeconds":cm,
        "machAfter":after,"wallUnix":Date().timeIntervalSince1970])
 }
 func stream(_ stream: SCStream, didOutputSampleBuffer sample: CMSampleBuffer,
             of type: SCStreamOutputType) {
  guard type == .screen, sample.isValid, let pixel = sample.imageBuffer else { return }
  guard let att = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: false)
   as? [[SCStreamFrameInfo: Any]], let raw = att.first?[.status] as? Int,
   raw == SCFrameStatus.complete.rawValue else { return }
  let pts = sample.presentationTimeStamp
  if first == nil {
   writer.startWriting(); writer.startSession(atSourceTime: pts)
  }
  guard input.isReadyForMoreMediaData else {
   skipped += 1; emit(["type":"dropped","ptsSeconds":pts.seconds]); return
  }
  let accepted = adaptor.append(pixel, withPresentationTime: pts)
  if accepted {
   if first == nil { first = pts; anchor("firstAppendedFrame") }
   last = pts; count += 1
  }
  emit(["type":"frame","ptsValue":pts.value,"ptsTimescale":pts.timescale,
        "ptsSeconds":pts.seconds,"accepted":accepted,
        "observedMachSeconds":AVAudioTime.seconds(forHostTime: mach_absolute_time())])
 }
 func finish() async {
  input.markAsFinished()
  await writer.finishWriting()
  anchor("finished")
  emit(["type":"summary","acceptedFrames":count,"notReadyFrames":skipped,
        "firstPTS":first?.seconds ?? -1,"lastPTS":last?.seconds ?? -1,
        "writerStatus":writer.status.rawValue,"error":writer.error?.localizedDescription ?? ""])
  try? log.close()
 }
}
@main struct CaptureVideo {
 static func main() async throws {
  let prefix = CommandLine.arguments[1], duration = Double(CommandLine.arguments[2])!
  let content = try await SCShareableContent.excludingDesktopWindows(false,onScreenWindowsOnly:true)
  let display = content.displays[0]
  let sink = try VideoSink(prefix: prefix,width:display.width,height:display.height)
  let config = SCStreamConfiguration()
  config.width=display.width; config.height=display.height
  config.pixelFormat=kCVPixelFormatType_32BGRA
  config.minimumFrameInterval=CMTime(value:1,timescale:30)
  config.capturesAudio=false; config.showsCursor=true; config.queueDepth=8
  let stream=SCStream(filter:SCContentFilter(display:display,excludingWindows:[]),
                     configuration:config,delegate:nil)
  let queue=DispatchQueue(label:"evidence.video")
  try stream.addStreamOutput(sink,type:.screen,sampleHandlerQueue:queue)
  sink.anchor("beforeStart")
  try await stream.startCapture()
  print("VIDEO READY \(display.width)x\(display.height)"); fflush(stdout)
  try await Task.sleep(for:.seconds(duration))
  try await stream.stopCapture()
  queue.sync {}
  await sink.finish()
  print("VIDEO FINISHED frames=\(sink.count)")
 }
}
