import LinkPresentation
import SwiftUI
import UIKit

struct CatchView: View {
  let record: CatchRecord
  let total: Int
  let again: () -> Void
  let home: () -> Void
  @State private var share: SharePayload?
  @State private var arrived = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Eyebrow(text: "An evening worth keeping")
        Spacer()
        Button(action: home) { Image(systemName: "xmark").frame(width: 44, height: 44) }
          .accessibilityLabel("Back to the shore").accessibilityIdentifier("result-home")
      }
      ScrollView {
        VStack(spacing: 16) {
          CatchCard(record: record)
            .scaleEffect(arrived || reduceMotion ? 1 : 0.85)
            .opacity(arrived ? 1 : 0)
          Text(
            total == 3
              ? "Violet Reach unlocked. A new shore awaits."
              : "+\(record.species.rare ? 2 : 1) glow bait · saved to your field journal"
          )
          .font(.system(size: 12)).multilineTextAlignment(.center)
        }
      }
      .scrollIndicators(.hidden)
      CapsuleAction(title: "One more cast", icon: "arrow.up.right", action: again)
      Button {
        let renderer = ImageRenderer(
          content:
            CatchCard(record: record).frame(width: 360).padding(24).background(Ink.night))
        renderer.scale = 3
        if let image = renderer.uiImage {
          share = SharePayload(
            image: image,
            text:
              "I caught a \(record.length) cm \(record.species.name) at \(record.lake.name) in Dusk Angler. \(record.species.rare ? "Rare" : "Common") · \(record.score) points."
          )
        }
      } label: {
        Label("Share this catch", systemImage: "square.and.arrow.up")
          .font(.system(size: 14)).frame(maxWidth: .infinity, minHeight: 44)
      }
      .accessibilityIdentifier("share-catch")
    }
    .padding(.horizontal, 24).padding(.bottom, 12)
    .background(Ink.night.opacity(0.48).ignoresSafeArea())
    .sheet(item: $share) { payload in ShareSheet(payload: payload) }
    .onAppear {
      withAnimation(reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.68)) {
        arrived = true
      }
    }
  }
}

struct CatchCard: View {
  let record: CatchRecord
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("DUSK ANGLER")
        Spacer()
        Image(systemName: "sun.horizon")
      }
      .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2)
      .padding(.bottom, 22)
      Eyebrow(
        text: record.species.rare ? "Rare specimen" : "A beautiful catch",
        color: Ink.night.opacity(0.7))
      Text(record.species.name).font(.system(size: 33, design: .serif))
        .minimumScaleFactor(0.7).lineLimit(1).padding(.top, 10)
      Text(record.species.latin).font(.system(size: 13, design: .serif)).italic()
        .foregroundStyle(Ink.night.opacity(0.6)).padding(.top, 5)
      ZStack {
        Circle().stroke(Ink.night.opacity(0.08), lineWidth: 1).frame(width: 165, height: 165)
        Circle().stroke(Ink.night.opacity(0.05), lineWidth: 1).frame(width: 200, height: 200)
        FishArt(species: record.species).frame(height: 162)
          .rotationEffect(.degrees(-8))
        if record.species.rare {
          Image(systemName: "sparkle").font(.system(size: 22, weight: .ultraLight))
            .foregroundStyle(Color(red: 0.58, green: 0.36, blue: 0.5))
            .offset(x: 110, y: -62)
        }
      }
      .frame(height: 210)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(record.length)").font(.system(size: 48, weight: .regular, design: .serif))
        Text("cm").font(.system(size: 17, design: .serif))
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          Text("\(record.score)").font(.system(size: 24, design: .serif))
          Text("CATCH SCORE").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(
            2)
        }
      }
      Rectangle().fill(Ink.night.opacity(0.18)).frame(height: 1).padding(.vertical, 16)
      HStack {
        Label(record.lake.name, systemImage: "location")
        Spacer()
        Text(record.date.formatted(.dateTime.month(.abbreviated).day()))
      }
      .font(.system(size: 11, weight: .medium))
      Text("Catch, admire, release.")
        .font(.system(size: 11, design: .serif)).italic()
        .foregroundStyle(Ink.night.opacity(0.6)).padding(.top, 15)
    }
    .padding(24)
    .foregroundStyle(Ink.night)
    .background(Ink.cream, in: RoundedRectangle(cornerRadius: 6))
    .overlay {
      RoundedRectangle(cornerRadius: 3).stroke(Ink.night.opacity(0.16), lineWidth: 1).padding(9)
    }
  }
}

struct SharePayload: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
  let payload: SharePayload
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: [CatchShareItem(payload: payload)], applicationActivities: nil)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

final class CatchShareItem: NSObject, UIActivityItemSource {
  let payload: SharePayload
  init(payload: SharePayload) { self.payload = payload }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController)
    -> Any
  {
    payload.image
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    payload.image
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    payload.text
  }

  func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController)
    -> LPLinkMetadata?
  {
    let metadata = LPLinkMetadata()
    metadata.title = payload.text
    metadata.imageProvider = NSItemProvider(object: payload.image)
    metadata.iconProvider = NSItemProvider(object: payload.image)
    return metadata
  }
}

struct FieldPanel: View {
  @ObservedObject var store: GameStore
  let panel: AnglerView.Panel
  @Environment(\.dismiss) private var dismiss
  var title: String {
    switch panel {
    case .journal: return "Field journal"
    case .waters: return "Other waters"
    case .settings: return "By the shore"
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Eyebrow(
            text: panel == .journal
              ? "\(store.progress.total) catches · \(store.progress.bait) glow bait"
              : "Dusk Angler", color: Ink.gold)
          switch panel {
          case .journal: journal
          case .waters: waters
          case .settings: settings
          }
        }
        .padding(24)
      }
      .background(Ink.night)
      .foregroundStyle(Ink.cream)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }.foregroundStyle(Ink.cream).accessibilityIdentifier(
            "panel-done")
        }
      }
    }
    .preferredColorScheme(.dark)
  }

  private var journal: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Small wonders,\ncarefully remembered.")
        .font(.system(size: 30, design: .serif))
      ForEach(Species.allCases) { species in
        let records = store.progress.catches.filter { $0.species == species }
        let largest = records.map(\.length).max()
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            FishArt(species: species, silhouette: records.isEmpty)
              .frame(width: 105, height: 64)
              .background(Ink.cream.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 6) {
              Text(species.name).font(.system(size: 20, design: .serif))
              Text(
                largest.map { "Largest \($0) cm · \(records.count) recorded" } ?? "Not yet observed"
              )
              .font(.system(size: 11)).foregroundStyle(Ink.cream.opacity(0.6))
            }
          }
          Text(species.behavior).font(.system(size: 13)).foregroundStyle(Ink.cream.opacity(0.7))
          Divider().overlay(Ink.cream.opacity(0.15)).padding(.top, 8)
        }
      }
      Text(
        "Every catch earns glow bait. Spend two to draw a rare fish to any silhouette. Your latest 100 catches are preserved."
      )
      .font(.system(size: 13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
    }
  }

  private var waters: some View {
    VStack(spacing: 26) {
      ForEach(Lake.allCases) { lake in
        let locked = lake == .violet && !store.progress.violetUnlocked
        VStack(alignment: .leading, spacing: 12) {
          ZStack(alignment: .bottomLeading) {
            Image("Lake").resizable().scaledToFill().frame(height: 150).clipped()
              .overlay(lake == .violet ? Color.indigo.opacity(0.4) : Color.clear)
            Text(lake.name).font(.system(size: 31, design: .serif)).padding(18)
              .shadow(color: Ink.night, radius: 8)
          }
          .clipShape(RoundedRectangle(cornerRadius: 5))
          Text(lake.subtitle).font(.system(size: 15, design: .serif)).italic()
          Text(
            locked
              ? "Opens after 3 catches · \(store.progress.total)/3"
              : lake.species.map(\.name).joined(separator: " · ")
          )
          .font(.system(size: 12)).foregroundStyle(Ink.cream.opacity(0.65))
          if !locked {
            CapsuleAction(
              title: store.lake == lake ? "Fish here again" : "Travel to \(lake.name)",
              icon: "arrow.right"
            ) {
              store.lake = lake
              dismiss()
              store.begin()
            }
          } else {
            Label("Keep exploring Amber Lake", systemImage: "lock")
              .font(.system(size: 13)).padding(.vertical, 10)
          }
        }
      }
    }
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Leave only ripples.").font(.system(size: 32, design: .serif))
      Toggle("Soft sound effects", isOn: $store.sound).tint(Ink.gold).accessibilityIdentifier(
        "sound-toggle")
      Toggle("Haptic feedback", isOn: $store.haptics).tint(Ink.gold).accessibilityIdentifier(
        "haptic-toggle")
      Divider()
      Text("A field guide to fishing").font(.system(size: 23, design: .serif))
      Text(
        "Aim at a fish and cast. When the float dips, tap HOOK. Hold the reel to bring your catch closer. Release before the fish surges; the amber warning gives you time. A full tension bar snaps the line. Five seconds of slack lets the fish escape."
      )
      .font(.system(size: 15)).lineSpacing(5).foregroundStyle(Ink.cream.opacity(0.75))
      Text(
        "Designed for quiet evenings. All progress stays on this device. Fish and their scientific names are imagined."
      )
      .font(.system(size: 13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
      Text(
        "Accessibility: supports Reduce Motion. With VoiceOver, activate Reel to toggle holding and releasing."
      )
      .font(.system(size: 13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
    }
  }
}
