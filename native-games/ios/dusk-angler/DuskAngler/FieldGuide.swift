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
    VStack(spacing: 12) {
      HStack {
        Eyebrow(text: "A moment, collected", color: Ink.gold)
        Spacer()
        Button(action: home) { Image(systemName: "xmark").frame(width: 44, height: 44) }
          .accessibilityLabel("Back to the shore").accessibilityIdentifier("result-home")
      }
      ScrollView {
        CatchCard(record: record)
          .scaleEffect(arrived || reduceMotion ? 1 : 0.85)
          .opacity(arrived ? 1 : 0)
      }
      .scrollIndicators(.visible)
      Text(
        total == 3
          ? "Violet Reach unlocked. A new shore awaits."
          : "+\(record.species.rare ? 2 : 1) glow bait · saved to your field journal"
      )
      .font(TypeStyle.body(12)).multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      PrimaryAction(title: "One more cast", icon: "arrow.up.right", action: again)
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
          .font(TypeStyle.label(13)).frame(maxWidth: .infinity, minHeight: 44)
      }
      .accessibilityIdentifier("share-catch")
    }
    .padding(.horizontal, 24).padding(.bottom, 12)
    .background(Ink.night.opacity(0.85).ignoresSafeArea())
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
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 10) {
        AnglerSeal().frame(width: 30, height: 30)
        VStack(alignment: .leading, spacing: 0) {
          Text("DUSK ANGLER").font(TypeStyle.display(18)).tracking(2)
          Text("THE EVENING COLLECTION").font(TypeStyle.label(7)).tracking(1.5)
        }
        Spacer()
        Text(record.species.rare ? "RARE\nFIND" : "FIELD\nRECORD")
          .font(TypeStyle.label(8)).tracking(1.1).multilineTextAlignment(.center)
          .padding(7)
          .overlay(Rectangle().strokeBorder(Ink.gold.opacity(0.7), lineWidth: 0.7))
      }
      .foregroundStyle(Ink.gold)
      .padding(.horizontal, 20).padding(.vertical, 16)
      .background(Ink.lake)
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .firstTextBaseline) {
          Eyebrow(
            text:
              "Specimen \(String(format: "%02d", (Species.allCases.firstIndex(of: record.species) ?? 0) + 1))",
            color: Ink.lake.opacity(0.6))
          Spacer()
          Text(record.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
            .font(TypeStyle.label(9)).tracking(1)
        }
        .padding(.top, 20)
        Text(record.species.name.uppercased()).font(TypeStyle.display(35))
          .minimumScaleFactor(0.7).lineLimit(1).padding(.top, 10)
        Text(record.species.latin).font(TypeStyle.specimen(15))
          .foregroundStyle(Ink.lake.opacity(0.7)).padding(.top, 1)
        FishArt(species: record.species)
          .frame(maxWidth: .infinity).frame(height: 160)
          .padding(.vertical, 8)
        SpecimenRuler()
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text("\(record.length)").font(TypeStyle.display(52)).tracking(-1)
          Text("cm").font(TypeStyle.body(15))
          Spacer()
          VStack(alignment: .trailing, spacing: 1) {
            Text("\(record.score)").font(TypeStyle.display(35))
            Text("CATCH SCORE").font(TypeStyle.label(8)).tracking(1.3)
          }
        }
        .padding(.top, 8)
        Rectangle().fill(Ink.night.opacity(0.15)).frame(height: 1).padding(.vertical, 15)
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("CAUGHT & RELEASED").font(TypeStyle.label(7)).tracking(1.5)
            Text(record.lake.name).font(TypeStyle.label(12))
          }
          Spacer()
          AnglerSeal().frame(width: 33, height: 33).opacity(0.5)
        }
        .padding(.bottom, 20)
      }
      .padding(.horizontal, 20)
      .foregroundStyle(Ink.night)
      .background(Ink.cream)
    }
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Ink.gold.opacity(0.4), lineWidth: 0.8))
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
  let replayTutorial: () -> Void
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
      .font(TypeStyle.body(15))
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
      Text("THE EVENING\nCOLLECTION")
        .font(TypeStyle.display(37)).lineSpacing(-2)
      ForEach(Species.allCases) { species in
        let records = store.progress.catches.filter { $0.species == species }
        let largest = records.map(\.length).max()
        VStack(alignment: .leading, spacing: 12) {
          ZStack(alignment: .topLeading) {
            Ink.cream
            FishArt(species: species, silhouette: records.isEmpty)
              .padding(.horizontal, 25).padding(.vertical, 18)
            Text(records.isEmpty ? "NOT YET OBSERVED" : species.rare ? "RARE FIND" : "COLLECTED")
              .font(TypeStyle.label(8)).tracking(1.5).padding(10)
              .foregroundStyle(Ink.night.opacity(0.55))
          }
          .frame(height: 150)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          HStack(alignment: .firstTextBaseline) {
            Text(species.name).font(TypeStyle.display(25))
            Spacer()
            if let largest {
              Text("\(largest) cm").font(TypeStyle.display(23)).foregroundStyle(Ink.gold)
            }
          }
          Text(species.behavior).font(TypeStyle.body(13)).foregroundStyle(Ink.cream.opacity(0.7))
          if !records.isEmpty {
            Text("\(records.count) recorded").font(TypeStyle.body(11)).foregroundStyle(
              Ink.cream.opacity(0.6))
          }
          Divider().overlay(Ink.cream.opacity(0.15)).padding(.top, 8)
        }
      }
      Text(
        "Every catch earns glow bait. Spend two to draw a rare fish to any silhouette. Your latest 100 catches are preserved."
      )
      .font(TypeStyle.body(13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
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
            Text(lake.name).font(TypeStyle.display(31)).padding(18)
              .shadow(color: Ink.night, radius: 8)
          }
          .clipShape(RoundedRectangle(cornerRadius: 5))
          Text(lake.subtitle).font(TypeStyle.specimen(16))
          Text(
            locked
              ? "Opens after 3 catches · \(store.progress.total)/3"
              : lake.species.map(\.name).joined(separator: " · ")
          )
          .font(TypeStyle.body(12)).foregroundStyle(Ink.cream.opacity(0.65))
          if !locked {
            PrimaryAction(
              title: store.lake == lake ? "Fish here again" : "Travel to \(lake.name)",
              icon: "arrow.right"
            ) {
              store.lake = lake
              dismiss()
              store.begin()
            }
          } else {
            Label("Keep exploring Amber Lake", systemImage: "lock")
              .font(TypeStyle.body(13)).padding(.vertical, 10)
          }
        }
      }
    }
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Leave only ripples.").font(TypeStyle.display(32))
      Toggle("Soft sound effects", isOn: $store.sound).tint(Ink.gold).accessibilityIdentifier(
        "sound-toggle")
      Toggle("Haptic feedback", isOn: $store.haptics).tint(Ink.gold).accessibilityIdentifier(
        "haptic-toggle")
      Divider()
      Text("A field guide to fishing").font(TypeStyle.display(23))
      PrimaryAction(title: "Replay tutorial", icon: "book") {
        dismiss()
        replayTutorial()
      }
      Text(
        "Aim at a fish and cast. When the float dips, tap HOOK. Hold the reel to bring your catch closer. Release before the fish surges; the brass warning gives you time. The reel’s scale shows line tension: reaching 100% snaps the line. Five seconds of slack lets the fish escape."
      )
      .font(TypeStyle.body(15)).lineSpacing(5).foregroundStyle(Ink.cream.opacity(0.75))
      Text(
        "Designed for quiet evenings. All progress stays on this device. Fish and their scientific names are imagined."
      )
      .font(TypeStyle.body(13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
      Text(
        "Accessibility: supports Reduce Motion. With VoiceOver, activate Reel to toggle holding and releasing."
      )
      .font(TypeStyle.body(13)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.6))
    }
  }
}
