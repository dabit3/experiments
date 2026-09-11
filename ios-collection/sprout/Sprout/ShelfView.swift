import SwiftUI

struct ShelfView: View {
  @EnvironmentObject private var store: PlantStore
  @State private var room: String?
  @State private var adding = false
  @State private var showSettings = false
  @Environment(\.dynamicTypeSize) private var typeSize

  private var visible: [Plant] { store.plants.filter { room == nil || $0.room == room } }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 23) {
        HStack {
          Eyebrow(text: "A little greener, every day")
          Spacer()
          Button {
            showSettings = true
          } label: {
            Image(systemName: "ellipsis").frame(width: 44, height: 44)
          }.accessibilityLabel("Shelf settings")
        }
        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Room to\ngrow.").font(.system(size: 48, weight: .regular, design: .serif))
              .lineSpacing(-3)
            Text("Your own small corner of green.").font(.subheadline).foregroundStyle(
              Palette.muted)
          }
          Spacer(minLength: 0)
          Button {
            adding = true
          } label: {
            Image(systemName: "plus").font(.title3).frame(width: 52, height: 52)
              .background(Palette.forest, in: Circle()).foregroundStyle(Palette.cream)
          }.accessibilityLabel("Add a plant")
        }
        if store.plants.contains(where: \.isSample) {
          HStack(spacing: 9) {
            Image(systemName: "sparkle")
            Text("A starter shelf, ready to make your own.").font(.caption)
          }.foregroundStyle(Palette.muted)
        }
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            roomChip(nil)
            ForEach(store.rooms, id: \.self) { roomChip($0) }
          }
        }
        if visible.isEmpty {
          VStack(spacing: 14) {
            Botanical(kind: .monstera).frame(width: 190, height: 210)
            Text("Every shelf starts\nwith one plant.").font(.system(.title, design: .serif))
              .multilineTextAlignment(.center)
            Button("Add your first plant") { adding = true }.buttonStyle(PrimaryButton())
          }.padding(.vertical, 20)
        } else {
          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: 20),
              count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 28
          ) {
            ForEach(visible) { plant in
              NavigationLink {
                PlantDetailView(plantID: plant.id)
              } label: {
                VStack(alignment: .leading, spacing: 6) {
                  PlantPortrait(plant: plant).frame(
                    height: typeSize.isAccessibilitySize ? 250 : 190
                  )
                  .frame(maxWidth: .infinity).clipped()
                  Rectangle().fill(Palette.line).frame(height: 3)
                    .shadow(color: Palette.forest.opacity(0.12), radius: 4, y: 4)
                  HStack {
                    Text(plant.name).font(.system(.title3, design: .serif).weight(.medium))
                    Spacer(minLength: 0)
                  }
                  Text(plant.kind.rawValue).font(.caption).foregroundStyle(Palette.muted)
                  HStack(spacing: 4) {
                    Image(systemName: plant.daysUntilDue() <= 0 ? "drop.fill" : "drop")
                    Text(plant.status())
                  }
                  .font(.caption.weight(.medium))
                  .foregroundStyle(plant.daysUntilDue() < 0 ? Palette.terracotta : Palette.muted)
                }
                .contentShape(Rectangle())
              }.buttonStyle(.plain)
                .accessibilityLabel("\(plant.name), \(plant.kind.rawValue), \(plant.status())")
            }
          }
        }
        HStack {
          Rectangle().fill(Palette.line).frame(height: 1)
          Eyebrow(text: "\(visible.count) little \(visible.count == 1 ? "life" : "lives")")
          Rectangle().fill(Palette.line).frame(height: 1)
        }.padding(.vertical, 12)
      }.padding(.horizontal, 24).padding(.bottom, 20)
    }
    .background(Palette.cream)
    .foregroundStyle(Palette.forest)
    .toolbar(.hidden, for: .navigationBar)
    .sheet(isPresented: $adding) { PlantEditor() }
    .sheet(isPresented: $showSettings) { ShelfSettings() }
    .onChange(of: store.rooms) { _, rooms in
      if let room, !rooms.contains(room) { self.room = nil }
    }
  }

  private func roomChip(_ value: String?) -> some View {
    Button {
      room = value
    } label: {
      Text(value ?? "All plants").font(.subheadline.weight(.medium)).padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundStyle(room == value ? Palette.cream : Palette.forest)
        .background(room == value ? Palette.forest : .clear, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.line, lineWidth: room == value ? 0 : 1))
    }.accessibilityAddTraits(room == value ? .isSelected : [])
  }
}

struct ShelfSettings: View {
  @EnvironmentObject private var store: PlantStore
  @Environment(\.dismiss) private var dismiss
  @State private var confirm = false
  var body: some View {
    NavigationStack {
      List {
        Section("Your private little garden") {
          Text(
            "Plants, notes, photos and watering history stay on this device. Sprout has no account or cloud service."
          )
          Text("Watering dates are gentle reminders to check the soil, never a command to water.")
        }
        if store.plants.contains(where: \.isSample) {
          Section("Starter collection") {
            Text(
              "Sunday, Olive, Cleo and Frida are sample plants. Add your own, or clear the samples for an empty shelf."
            )
            Button("Remove sample plants", role: .destructive) { confirm = true }
          }
        }
        Section {
          Text("Sprout · Made for slow growth").font(.system(.body, design: .serif))
        }
      }.scrollContentBackground(.hidden).background(Palette.cream)
        .navigationTitle("On this shelf")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .confirmationDialog(
          "Remove the starter collection?", isPresented: $confirm, titleVisibility: .visible
        ) {
          Button("Remove sample plants", role: .destructive) { store.removeSamples() }
        } message: {
          Text("Your own plants will stay. Sample notes and care history will be deleted.")
        }
    }
  }
}
