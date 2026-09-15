import AVFoundation
import AppKit
import DevinCore

private final class ExportCancellation: @unchecked Sendable {
    private let exporter: AVAssetExportSession
    init(_ exporter: AVAssetExportSession) { self.exporter = exporter }
    func cancel() { exporter.cancelExport() }
}

struct ComposedMedia {
    let composition: AVMutableComposition
    let video: AVMutableVideoComposition?
    let audio: AVMutableAudioMix
}

enum MediaEngine {
    static func compose(_ clips: [MediaClip], video: Bool) async throws -> ComposedMedia {
        guard !clips.isEmpty else { throw DocumentError.invalid("Import at least one clip first.") }
        let composition = AVMutableComposition()
        let entries = SequenceLayout.entries(clips)
        var videoLayers: [(SequenceEntry, AVMutableCompositionTrack, CGAffineTransform)] = []
        var audioParameters: [AVMutableAudioMixInputParameters] = []
        for entry in entries {
            let clip = entry.clip, cursor = CMTime(seconds: entry.position, preferredTimescale: 60000)
            try Task.checkCancellation()
            guard FileManager.default.fileExists(atPath: clip.url.path) else { throw DocumentError.invalid("The source file “\(clip.url.lastPathComponent)” is missing. Restore it to its original location or re-import it.") }
            let asset = AVURLAsset(url: clip.url)
            let range = CMTimeRange(start: CMTime(seconds: clip.start, preferredTimescale: 60000), duration: CMTime(seconds: clip.duration, preferredTimescale: 60000))
            if video && clip.audioOnly != true {
                guard let source = try await asset.loadTracks(withMediaType: .video).first,
                      let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw DocumentError.invalid("\(clip.name) has no video track.") }
                try track.insertTimeRange(range, of: source, at: cursor)
                let size = try await source.load(.naturalSize)
                let transform = try await source.load(.preferredTransform)
                let bounds = CGRect(origin: .zero, size: size).applying(transform)
                guard bounds.width != 0, bounds.height != 0 else { throw DocumentError.invalid("The video frame dimensions are invalid.") }
                let scale = min(1920 / abs(bounds.width), 1080 / abs(bounds.height))
                let effect = clip.videoTransform ?? VideoTransform()
                let normalized = transform.concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
                    .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                    .concatenating(CGAffineTransform(translationX: -abs(bounds.width) * scale / 2, y: -abs(bounds.height) * scale / 2))
                    .concatenating(CGAffineTransform(scaleX: effect.scale, y: effect.scale))
                    .concatenating(CGAffineTransform(rotationAngle: effect.rotation * .pi / 180))
                    .concatenating(CGAffineTransform(translationX: 960 + effect.x, y: 540 + effect.y))
                videoLayers.append((entry, track, normalized))
            }
            if let source = try await asset.loadTracks(withMediaType: .audio).first {
                guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw DocumentError.invalid("An audio track could not be created.") }
                try track.insertTimeRange(range, of: source, at: cursor)
                let parameters = AVMutableAudioMixInputParameters(track: track)
                let fadeIn = min(clip.fadeIn, clip.duration / 2), fadeOut = min(clip.fadeOut, clip.duration / 2)
                let gain = clip.muted == true ? Float(0) : Float(clip.gain)
                parameters.setVolume(gain, at: cursor)
                if fadeIn > 0 { parameters.setVolumeRamp(fromStartVolume: 0, toEndVolume: gain, timeRange: CMTimeRange(start: cursor, duration: CMTime(seconds: fadeIn, preferredTimescale: 60000))) }
                if fadeOut > 0 { parameters.setVolumeRamp(fromStartVolume: gain, toEndVolume: 0, timeRange: CMTimeRange(start: cursor + range.duration - CMTime(seconds: fadeOut, preferredTimescale: 60000), duration: CMTime(seconds: fadeOut, preferredTimescale: 60000))) }
                audioParameters.append(parameters)
            } else if !video { throw DocumentError.invalid("\(clip.name) has no audio track.") }
        }
        let mix = AVMutableAudioMix(); mix.inputParameters = audioParameters
        var videoComposition: AVMutableVideoComposition?
        if video && !videoLayers.isEmpty {
            let boundaries = Set([0.0] + entries.flatMap { [$0.position, $0.end] }).sorted()
            var instructions: [AVMutableVideoCompositionInstruction] = []
            for (start, end) in zip(boundaries, boundaries.dropFirst()) where end > start {
                let instruction = AVMutableVideoCompositionInstruction()
                let time = CMTime(seconds: start, preferredTimescale: 60000)
                instruction.timeRange = CMTimeRange(start: time, duration: CMTime(seconds: end - start, preferredTimescale: 60000))
                instruction.backgroundColor = NSColor.black.cgColor
                let active = videoLayers.filter { $0.0.position <= start + 0.00001 && $0.0.end > start + 0.00001 }.sorted { a, b in a.0.track == b.0.track ? a.0.position > b.0.position : a.0.track > b.0.track }
                instruction.layerInstructions = active.map { entry, track, transform in
                    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
                    layer.setTransform(transform, at: time)
                    layer.setOpacity(Float(entry.clip.videoTransform?.opacity ?? 1), at: time)
                    return layer
                }
                instructions.append(instruction)
            }
            let value = AVMutableVideoComposition()
            value.instructions = instructions; value.renderSize = CGSize(width: 1920, height: 1080); value.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition = value
        }
        return ComposedMedia(composition: composition, video: videoComposition, audio: mix)
    }
    static func exportMovie(_ clips: [MediaClip], to url: URL, progress: @escaping (Double) -> Void) async throws {
        let media = try await compose(clips, video: true)
        guard let exporter = AVAssetExportSession(asset: media.composition, presetName: AVAssetExportPresetHighestQuality) else { throw DocumentError.invalid("The movie exporter could not be created.") }
        exporter.outputURL = url; exporter.outputFileType = .mp4
        exporter.videoComposition = media.video; exporter.audioMix = media.audio
        exporter.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: SequenceLayout.duration(clips), preferredTimescale: 60000))
        exporter.shouldOptimizeForNetworkUse = true
        let monitor = Task {
            while !Task.isCancelled { progress(Double(exporter.progress)); try? await Task.sleep(nanoseconds: 200_000_000) }
        }
        defer { monitor.cancel() }
        let cancellation = ExportCancellation(exporter)
        await withTaskCancellationHandler(operation: { await exporter.export() }, onCancel: { cancellation.cancel() })
        try Task.checkCancellation()
        guard exporter.status == .completed else { throw exporter.error ?? DocumentError.invalid("Movie export failed.") }
    }
    static func exportAudio(_ clips: [MediaClip], to url: URL, progress: @escaping (Double) -> Void) async throws {
        let media = try await compose(clips, video: false)
        let reader = try AVAssetReader(asset: media.composition)
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48000, AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false]
        let output = AVAssetReaderAudioMixOutput(audioTracks: media.composition.tracks(withMediaType: .audio), audioSettings: settings)
        output.audioMix = media.audio
        guard reader.canAdd(output) else { throw DocumentError.invalid("The audio stream could not be decoded.") }
        reader.add(output)
        let writer = try AVAssetWriter(outputURL: url, fileType: .wav)
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        guard writer.canAdd(input) else { throw DocumentError.invalid("The WAV encoder is unavailable.") }
        writer.add(input)
        guard writer.startWriting(), reader.startReading() else { throw writer.error ?? reader.error ?? DocumentError.invalid("Audio export could not start.") }
        writer.startSession(atSourceTime: .zero)
        let duration = SequenceLayout.duration(clips)
        do {
            while let sample = output.copyNextSampleBuffer() {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    if writer.status == .failed { throw writer.error ?? DocumentError.invalid("The audio encoder stopped.") }
                    try await Task.sleep(nanoseconds: 2_000_000)
                }
                guard input.append(sample) else { throw writer.error ?? DocumentError.invalid("Audio data could not be written.") }
                progress(CMSampleBufferGetPresentationTimeStamp(sample).seconds / duration)
            }
            guard reader.status == .completed else { throw reader.error ?? DocumentError.invalid("The source audio could not be fully decoded.") }
            input.markAsFinished(); await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? DocumentError.invalid("The WAV file could not be finalized.") }
        } catch { reader.cancelReading(); writer.cancelWriting(); throw error }
    }
    static func waveform(url: URL, bins: Int = 900) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return [] }
        let duration = try await asset.load(.duration).seconds
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 8000, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false])
        reader.add(output)
        guard reader.startReading() else { throw reader.error ?? DocumentError.invalid("The waveform could not be read.") }
        var peaks = [Float](repeating: 0, count: bins)
        let samplesPerBin = max(1, duration * 8000 / Double(bins))
        var index = 0
        while let sample = output.copyNextSampleBuffer() {
            if Task.isCancelled { reader.cancelReading(); throw CancellationError() }
            guard let block = CMSampleBufferGetDataBuffer(sample) else { continue }
            var pointer: UnsafeMutablePointer<Int8>?
            var length = 0
            guard CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer) == kCMBlockBufferNoErr, let pointer else { continue }
            pointer.withMemoryRebound(to: Float.self, capacity: length / 4) { data in
                for i in 0..<(length / 4) {
                    let bin = min(bins - 1, Int(Double(index) / samplesPerBin))
                    peaks[bin] = max(peaks[bin], abs(data[i])); index += 1
                }
            }
        }
        if reader.status == .failed { throw reader.error ?? DocumentError.invalid("Waveform decoding failed.") }
        return peaks
    }
    static func createTone(at url: URL, duration: Double = 8) throws {
        let sampleRate = 48000.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        var settings = format.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let total = Int(sampleRate * duration)
        var written = 0
        while written < total {
            let count = min(4096, total - written)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count))!
            buffer.frameLength = AVAudioFrameCount(count)
            for i in 0..<count {
                let t = Double(written + i) / sampleRate
                let beat = t.truncatingRemainder(dividingBy: 0.5)
                let kick = sin(2 * .pi * (65 * beat + 25 * (1 - exp(-beat * 20)))) * exp(-beat * 13)
                let note = [220.0, 261.63, 329.63, 293.66][Int(t) % 4]
                let pad = (sin(2 * .pi * note * t) + sin(2 * .pi * note * 1.5 * t)) * 0.1
                let fade = min(1, t / 0.1, (duration - t) / 0.5)
                let value = Float((kick * 0.45 + pad) * fade)
                buffer.floatChannelData![0][i] = value; buffer.floatChannelData![1][i] = value * 0.9
            }
            try file.write(from: buffer); written += count
        }
    }
}
