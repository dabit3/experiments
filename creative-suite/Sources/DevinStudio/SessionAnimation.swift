import SwiftUI
import DevinCore

extension StudioSession {
    func togglePlayback() {
        let media = tool == .cut || tool == .sound
        if media && (document.clips.isEmpty || player.currentItem == nil) { message = "Import media and wait for the preview to load."; return }
        let area = tool == .motion ? document.playbackArea : WorkArea(start: 0, end: media ? document.sequenceDuration : Double(document.pageCount) / Double(document.fps))
        if !isPlaying {
            if tool == .frame { playhead = Double(page) / Double(document.fps) }
            else if playhead < area.start || playhead >= area.lastFrame(fps: document.fps) { playhead = area.start; if media { player.seek(to: .zero) } }
        }
        isPlaying.toggle()
    }
    func setAnimationValue(_ value: Double, property: AnimationProperty, layerID: UUID, addKey: Bool = false) {
        guard value.isFinite, let index = document.elements.firstIndex(where: { $0.id == layerID && !$0.locked }) else { return }
        let bounded = min(property.limits.upperBound, max(property.limits.lowerBound, value)), time = playhead
        mutate { d in
            if addKey || d.elements[index].effectiveAnimationChannels.contains(where: { $0.property == property }) {
                d.elements[index].setPropertyKeyframe(property, at: time, value: bounded, tolerance: 0.5 / Double(d.fps))
            } else { d.elements[index].setBaseValue(bounded, for: property) }
        }
    }
    func toggleAnimation(_ property: AnimationProperty, layerID: UUID) {
        guard let index = document.elements.firstIndex(where: { $0.id == layerID && !$0.locked }) else { return }
        let element = document.elements[index], time = playhead
        if element.effectiveAnimationChannels.contains(where: { $0.property == property }) { mutate { $0.elements[index].disableAnimation(property, at: time) } }
        else { setAnimationValue(element.animationValue(property, at: time), property: property, layerID: layerID, addKey: true) }
    }
    func animationBinding(_ property: AnimationProperty, layerID: UUID) -> Binding<Double> {
        let multiplier = property == .scale || property == .opacity ? 100.0 : 1.0
        return Binding(get: { (self.document.elements.first { $0.id == layerID }?.animationValue(property, at: self.playhead) ?? 0) * multiplier }, set: { self.setAnimationValue($0 / multiplier, property: property, layerID: layerID) })
    }
    func moveAnimationKey(_ id: UUID, property: AnimationProperty, layerID: UUID, time: Double) {
        guard let index = document.elements.firstIndex(where: { $0.id == layerID && !$0.locked }) else { return }
        var layer = document.elements[index]; layer.migrateAnimationChannels()
        guard let c = layer.animationChannels?.firstIndex(where: { $0.property == property }), var key = layer.animationChannels?[c].keyframes.first(where: { $0.id == id }) else { return }
        let snapped = min(document.duration, max(0, (time * Double(document.fps)).rounded() / Double(document.fps)))
        layer.animationChannels?[c].keyframes.removeAll { $0.id == id || abs($0.time - snapped) < 0.5 / Double(document.fps) }
        key.time = snapped; layer.animationChannels?[c].keyframes.append(key); layer.animationChannels?[c].keyframes.sort { $0.time < $1.time }
        document.elements[index] = layer
    }
    func deleteAnimationKey(_ id: UUID, property: AnimationProperty, layerID: UUID) {
        guard let index = document.elements.firstIndex(where: { $0.id == layerID && !$0.locked }) else { return }
        let time = playhead
        mutate { d in
            let value = d.elements[index].animationValue(property, at: time)
            d.elements[index].migrateAnimationChannels()
            guard let c = d.elements[index].animationChannels?.firstIndex(where: { $0.property == property }) else { return }
            d.elements[index].animationChannels?[c].keyframes.removeAll { $0.id == id }
            if d.elements[index].animationChannels?[c].keyframes.isEmpty == true {
                d.elements[index].animationChannels?.remove(at: c); d.elements[index].setBaseValue(value, for: property)
            }
        }
    }
    func setChannelInterpolation(_ interpolation: Interpolation, property: AnimationProperty, layerID: UUID) {
        guard let index = document.elements.firstIndex(where: { $0.id == layerID && !$0.locked }) else { return }
        mutate { d in
            d.elements[index].migrateAnimationChannels()
            guard let c = d.elements[index].animationChannels?.firstIndex(where: { $0.property == property }) else { return }
            for k in d.elements[index].animationChannels![c].keyframes.indices { d.elements[index].animationChannels![c].keyframes[k].interpolation = interpolation }
        }
    }
    func navigateKeyframe(_ direction: Int, property: AnimationProperty, layerID: UUID) {
        let times = document.elements.first { $0.id == layerID }?.effectiveAnimationChannels.first { $0.property == property }?.keyframes.map(\.time).sorted() ?? []
        if direction < 0, let time = times.last(where: { $0 < playhead - 0.00001 }) { playhead = time }
        if direction > 0, let time = times.first(where: { $0 > playhead + 0.00001 }) { playhead = time }
    }
    func workAreaBinding(start: Bool) -> Binding<Double> {
        Binding(get: { start ? self.document.playbackArea.start : self.document.playbackArea.end }, set: { value in
            self.mutate { d in
                var range = d.playbackArea
                let step = min(1 / Double(d.fps), d.duration / 2)
                if start { range.start = max(0, min(value, range.end - step)) }
                else { range.end = max(range.start + step, min(value, d.duration)) }
                d.workArea = range
            }
        })
    }
}
