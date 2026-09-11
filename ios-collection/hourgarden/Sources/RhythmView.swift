import SwiftUI

struct RhythmView: View {
  @EnvironmentObject private var store: GardenStore
  private var minutes: Int { Int(store.focusedSeconds(on: Date()) / 60) }
  private var days: [Date] {
    (-6...0).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          Eyebrow(text: Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
          Text("Find your rhythm.")
            .font(.system(size: 39, design: .serif))
          Text("Consistency is a gentle thing.")
            .font(.subheadline).foregroundStyle(Palette.muted)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(minutes)").font(.system(size: 88, weight: .light, design: .serif))
            Text("/ \(store.data.dailyGoal) min")
              .font(.system(.title2, design: .serif)).foregroundStyle(Palette.muted)
          }
          VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geometry in
              ZStack(alignment: .leading) {
                Capsule().fill(Palette.sage.opacity(0.12))
                Capsule().fill(Palette.sage)
                  .frame(
                    width: geometry.size.width
                      * min(1, Double(minutes) / Double(store.data.dailyGoal)))
              }
            }
            .frame(height: 6)
            Text(
              minutes >= store.data.dailyGoal
                ? "Your daily intention, fulfilled."
                : "Mindful minutes today · a goal, never a demand."
            )
            .font(.caption).foregroundStyle(Palette.muted)
          }
          Divider()
          Eyebrow(text: "The last seven days")
          HStack(alignment: .bottom, spacing: 12) {
            ForEach(days, id: \.self) { day in
              let count = Int(store.focusedSeconds(on: day) / 60)
              VStack(spacing: 10) {
                Text("\(count)").font(.caption2).foregroundStyle(Palette.muted)
                RoundedRectangle(cornerRadius: 4)
                  .fill(
                    Calendar.current.isDateInToday(day) ? Palette.sage : Palette.sage.opacity(0.3)
                  )
                  .frame(
                    height: max(4, min(100, Double(count) / Double(store.data.dailyGoal) * 100)))
                Text(day, format: .dateTime.weekday(.narrow))
                  .font(.caption)
              }
              .frame(maxWidth: .infinity)
              .accessibilityElement(children: .ignore)
              .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(count) minutes")
            }
          }
          .frame(height: 145, alignment: .bottom)
          Divider()
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
              Text("\(store.data.specimens.filter { !$0.isPreview }.count)")
                .font(.system(.largeTitle, design: .serif))
              Text("Rituals completed").font(.caption).foregroundStyle(Palette.muted)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
              Text("\(store.data.specimens.count)")
                .font(.system(.largeTitle, design: .serif))
              Text("Specimens grown").font(.caption).foregroundStyle(Palette.muted)
            }
          }
          Text(
            "Preview plants live in your herbarium.\nOnly full rituals count toward your focus totals."
          )
          .font(.footnote).foregroundStyle(Palette.muted)
          Text("“Attention is how we water\nwhat we want to grow.”")
            .font(.system(.title2, design: .serif).italic())
            .padding(.top, 10)
        }
        .padding(28)
      }
      .modifier(Paper())
      .toolbar(.hidden, for: .navigationBar)
    }
  }
}

struct SettingsView: View {
  @EnvironmentObject private var store: GardenStore
  @Environment(\.dismiss) private var dismiss
  @State private var reset = false
  var body: some View {
    NavigationStack {
      Form {
        Section {
          Stepper(
            "Daily intention: \(store.data.dailyGoal) minutes",
            value: Binding(get: { store.data.dailyGoal }, set: { store.setGoal($0) }),
            in: 15...240, step: 15)
        } header: {
          Text("Your pace")
        } footer: {
          Text("A soft target for your Rhythm page. There’s no streak to lose.")
        }
        Section("Made for quiet") {
          Label("No accounts. No distractions.", systemImage: "leaf")
          Text(
            "Your garden is stored on this device. Running rituals use the clock, so they continue while the app is closed. Paused rituals stay paused."
          )
          Text(
            "No alerts or sound play in the background. Come back when you’re ready; your plant will be waiting."
          )
          Text(
            "Focus totals belong to the day a ritual finishes. Previews are labeled and excluded.")
        }
        .font(.subheadline)
        Section("Your data") {
          Button("Reset my garden", role: .destructive) { reset = true }
        }
        Section {
          Text("Hourgarden 1.0\nA little time. A little growth.")
            .font(.system(.body, design: .serif))
        }
      }
      .scrollContentBackground(.hidden)
      .modifier(Paper())
      .navigationTitle("Tend your garden")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
      .confirmationDialog(
        "Start with an empty garden?", isPresented: $reset, titleVisibility: .visible
      ) {
        Button("Reset everything", role: .destructive) {
          store.reset()
          dismiss()
        }
      } message: {
        Text(
          "All specimens, reflections, settings and any active ritual will be removed. This cannot be undone."
        )
      }
    }
  }
}
