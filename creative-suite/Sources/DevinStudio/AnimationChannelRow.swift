import SwiftUI
import DevinCore

struct AnimationChannelRow: View {
    @ObservedObject var session: StudioSession
    let layerID: UUID
    let property: AnimationProperty
    @State private var dragOrigin: Double?
    var layer: CanvasElement? { session.document.elements.first { $0.id == layerID } }
    var channel: AnimationChannel? { layer?.effectiveAnimationChannels.first { $0.property == property } }
    var range: ClosedRange<Double> { property == .opacity ? 0...100 : property == .scale ? 0.1...10000 : -100000...100000 }
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                ProIcon(symbol: "stopwatch", help: "Toggle " + property.title + " animation", active: channel != nil, size: 20) { session.toggleAnimation(property, layerID: layerID) }
                Text(property.title).font(.system(size: 10)).frame(width: 76, alignment: .leading)
                ProField(label: "", value: session.animationBinding(property, layerID: layerID), range: range, suffix: property == .opacity || property == .scale ? "%" : property == .rotation ? "°" : "").frame(width: 87)
                ProIcon(symbol: "chevron.left", help: "Previous keyframe", size: 18) { session.navigateKeyframe(-1, property: property, layerID: layerID) }
                ProIcon(symbol: "diamond", help: "Add property keyframe", size: 19) { if let layer { session.setAnimationValue(layer.animationValue(property, at: session.playhead), property: property, layerID: layerID, addKey: true) } }
                ProIcon(symbol: "chevron.right", help: "Next keyframe", size: 18) { session.navigateKeyframe(1, property: property, layerID: layerID) }
                Menu {
                    ForEach(Interpolation.allCases, id: \.self) { interpolation in Button(interpolation.title) { session.setChannelInterpolation(interpolation, property: property, layerID: layerID) } }
                } label: { Image(systemName: "ellipsis").font(.system(size: 10)) }.menuStyle(.borderlessButton).frame(width: 20).disabled(channel == nil)
                Spacer(minLength: 0)
            }.padding(.leading, 42).frame(width: 400, height: 27).disabled(layer?.locked == true)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Color(hex: "222222")
                    ForEach(channel?.keyframes ?? []) { key in
                        Image(systemName: key.interpolation == .hold ? "square.fill" : "diamond.fill").font(.system(size: 9)).foregroundStyle(ProTheme.blue)
                            .frame(width: 12, height: 24).contentShape(Rectangle())
                            .offset(x: max(0, min(geometry.size.width - 12, key.time / session.document.duration * geometry.size.width - 6)))
                            .onTapGesture { session.select(layerID); session.playhead = key.time }
                            .gesture(DragGesture(minimumDistance: 3).onChanged { value in
                                guard layer?.locked != true else { return }
                                if dragOrigin == nil { dragOrigin = key.time; session.beginTransaction() }
                                session.moveAnimationKey(key.id, property: property, layerID: layerID, time: (dragOrigin ?? key.time) + value.translation.width / geometry.size.width * session.document.duration)
                            }.onEnded { _ in session.endTransaction(); dragOrigin = nil })
                            .contextMenu { Button("Delete Keyframe") { session.deleteAnimationKey(key.id, property: property, layerID: layerID) } }
                    }
                    Rectangle().fill(ProTheme.blue).frame(width: 1).offset(x: min(geometry.size.width - 1, session.playhead / session.document.duration * geometry.size.width)).allowsHitTesting(false)
                }
            }.frame(height: 27)
        }.background(Color(hex: "292929"))
    }
}
