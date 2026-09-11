import SwiftUI

struct CookView: View {
  let recipe: Recipe
  @EnvironmentObject private var store: KitchenStore
  @Environment(\.dismiss) private var dismiss
  @State private var showTimers = false
  @State private var showIngredients = false
  @State private var showRestart = false
  @State private var finished = false

  private var index: Int { min(store.state.cookStep, recipe.steps.count - 1) }
  private var step: CookStep { recipe.steps[index] }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          Label(finished ? "Close" : "Save & close", systemImage: "xmark").font(
            .subheadline.weight(.medium)
          )
          .frame(minHeight: 44)
        }
        Spacer()
        Button {
          showTimers = true
        } label: {
          Image(systemName: "timer").frame(width: 48, height: 48)
        }.accessibilityLabel("Kitchen timers")
      }.padding(.horizontal, 24).padding(.top, 10)
      if finished {
        ScrollView {
          VStack(alignment: .leading, spacing: 26) {
            Eyebrow(text: "The best part").foregroundStyle(Color(red: 1, green: 0.62, blue: 0.44))
            Text("Supper\nis served.").font(.editorial(60)).lineSpacing(-3)
            FoodArt(style: recipe.style).frame(height: 280).clipShape(
              RoundedRectangle(cornerRadius: 22))
            Text(
              "You made \(recipe.title.replacingOccurrences(of: "\n", with: " ").lowercased()). Take a seat. You’ve earned it."
            )
            .font(.title3).lineSpacing(5)
            MainButton(title: "Done cooking", symbol: "checkmark") { dismiss() }
            Button {
              store.beginCooking(recipe)
              finished = false
            } label: {
              Text("Cook it again").font(.headline).frame(maxWidth: .infinity, minHeight: 52)
            }
          }.padding(24)
        }
      } else {
        HStack(spacing: 7) {
          ForEach(recipe.steps.indices, id: \.self) { number in
            Capsule().fill(
              number <= index ? Color(red: 1, green: 0.52, blue: 0.35) : .white.opacity(0.15)
            ).frame(height: 4)
          }
        }.padding(.horizontal, 24).padding(.vertical, 20).accessibilityHidden(true)
        ScrollView {
          VStack(alignment: .leading, spacing: 25) {
            HStack {
              Eyebrow(text: "Step \(index + 1) of \(recipe.steps.count)")
              Spacer()
              Text("\(store.servings(for: recipe)) servings").font(.subheadline)
            }.foregroundStyle(Color(red: 1, green: 0.66, blue: 0.48))
            Text(step.title).font(.editorial(49)).lineSpacing(-2)
            Text(step.instruction).font(.title3).lineSpacing(8)
              .fixedSize(horizontal: false, vertical: true)
            if let name = step.timerName {
              let id = "\(recipe.id)-\(index)"
              if store.state.timers[id] != nil {
                TimerCard(id: id)
              } else {
                Button {
                  store.makeTimer(id: id, name: name, seconds: step.seconds)
                  store.toggleTimer(id)
                } label: {
                  HStack {
                    Image(systemName: "timer").font(.title2)
                    VStack(alignment: .leading, spacing: 5) {
                      Text("Start \(name.lowercased()) timer").font(.headline)
                      Text(timerText(TimeInterval(step.seconds))).font(.title2.monospacedDigit())
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                  }.padding(22).frame(minHeight: 96)
                    .foregroundStyle(Palette.ink).background(
                      Palette.paper, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
              }
            }
            Button {
              showIngredients = true
            } label: {
              Label("Check ingredients", systemImage: "list.bullet").font(
                .subheadline.weight(.medium)
              ).frame(minHeight: 48)
            }
            if index < recipe.steps.count - 1 {
              VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Up next").opacity(0.6)
                Text(recipe.steps[index + 1].title).font(.editorial(25))
              }.padding(.top, 10)
            }
          }.padding(24)
        }.id(index)
        VStack(spacing: 8) {
          MainButton(
            title: index == recipe.steps.count - 1 ? "Supper is ready" : "Next step",
            symbol: index == recipe.steps.count - 1 ? "checkmark" : "arrow.right"
          ) {
            if index == recipe.steps.count - 1 {
              store.finishCooking()
              finished = true
            } else {
              store.state.cookStep = index + 1
            }
          }
          HStack {
            Button {
              store.state.cookStep = max(0, index - 1)
            } label: {
              Label("Previous", systemImage: "arrow.left").frame(minHeight: 44)
            }.disabled(index == 0).opacity(index == 0 ? 0.35 : 1)
            Spacer()
            Button("Start over") { showRestart = true }.frame(minHeight: 44)
          }.font(.subheadline)
        }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)
      }
    }
    .background(Palette.ink).foregroundStyle(Palette.paper)
    .preferredColorScheme(.dark)
    .sheet(isPresented: $showTimers) { TimerRoomView() }
    .sheet(isPresented: $showIngredients) {
      NavigationStack {
        List(recipe.ingredients) { ingredient in
          HStack {
            Text(ingredient.name)
            Spacer()
            Text(ingredient.scaled(store.servings(for: recipe), from: recipe.servings).amount)
          }
        }.navigationTitle("For \(store.servings(for: recipe)) servings")
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { showIngredients = false } }
          }
      }.tint(Palette.red).preferredColorScheme(.light)
    }
    .confirmationDialog(
      "Start this recipe again?", isPresented: $showRestart, titleVisibility: .visible
    ) {
      Button("Start over") { store.state.cookStep = 0 }
      Button("Keep cooking", role: .cancel) {}
    } message: {
      Text("Returns to step 1. Running timers keep going.")
    }
    .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
    .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
  }
}

func timerText(_ seconds: TimeInterval) -> String {
  let seconds = Int(ceil(max(0, seconds)))
  let hours = seconds / 3600
  return hours > 0
    ? String(format: "%d:%02d:%02d", hours, seconds / 60 % 60, seconds % 60)
    : String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

struct TimerCard: View {
  let id: String
  @EnvironmentObject private var store: KitchenStore
  @State private var edit = false

  var body: some View {
    if let timer = store.state.timers[id] {
      TimelineView(.periodic(from: .now, by: 1)) { timeline in
        let done = timer.isFinished(at: timeline.date)
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            Label(timer.name, systemImage: done ? "checkmark.circle.fill" : "timer")
              .font(.headline)
            Spacer()
            Button {
              edit = true
            } label: {
              Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
            }.accessibilityLabel("Adjust \(timer.name) timer")
          }
          HStack(alignment: .firstTextBaseline) {
            Text(timerText(timer.remaining(at: timeline.date)))
              .font(.system(size: 48, weight: .medium, design: .rounded)).monospacedDigit()
              .accessibilityLabel(
                "\(Int(ceil(timer.remaining(at: timeline.date)))) seconds remaining")
            Spacer()
            Text(done ? "Ready!" : (timer.deadline == nil ? "Paused" : "Running"))
              .font(.subheadline.weight(.semibold))
          }
          HStack(spacing: 16) {
            Button {
              store.toggleTimer(id)
            } label: {
              Label(
                done ? "Run again" : (timer.deadline == nil ? "Start" : "Pause"),
                systemImage: done || timer.deadline == nil ? "play.fill" : "pause.fill"
              )
              .font(.headline).frame(maxWidth: .infinity, minHeight: 48)
              .background(Palette.ink, in: Capsule()).foregroundStyle(Palette.paper)
            }.buttonStyle(.plain)
            Button("Reset") { store.resetTimer(id) }.font(.subheadline.weight(.medium)).frame(
              minWidth: 60, minHeight: 48)
          }
        }.padding(20).background(
          done ? Color(red: 0.81, green: 0.87, blue: 0.66) : Palette.paper,
          in: RoundedRectangle(cornerRadius: 18)
        )
        .foregroundStyle(Palette.ink)
        .onChange(of: done) { _, value in
          if value {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(
              notification: .announcement, argument: "\(timer.name) timer is ready")
          }
        }
      }
      .sheet(isPresented: $edit) { TimerEditor(existing: timer) }
    }
  }
}

struct TimerRoomView: View {
  @EnvironmentObject private var store: KitchenStore
  @Environment(\.dismiss) private var dismiss
  @State private var newTimer = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Eyebrow(text: "A little help with the timing").foregroundStyle(Palette.red)
          Text("Take your time.").font(.editorial(39))
          Text("Timers keep time when you leave. Alerts appear while the app is open.")
            .font(.subheadline).foregroundStyle(Palette.muted)
          MainButton(title: "New kitchen timer", symbol: "plus") { newTimer = true }
          if store.state.timers.isEmpty {
            Text("No timers on the go.\nStart one here or inside a recipe.").font(.title3)
              .foregroundStyle(Palette.muted).padding(.vertical, 24)
          }
          ForEach(store.state.timers.values.sorted { $0.id < $1.id }) { timer in
            VStack(alignment: .trailing, spacing: 0) {
              TimerCard(id: timer.id)
              Button("Remove timer", role: .destructive) {
                store.state.timers.removeValue(forKey: timer.id)
              }
              .font(.caption).frame(minHeight: 44)
            }
          }
        }.padding(24)
      }.background(Color(red: 0.92, green: 0.89, blue: 0.83)).foregroundStyle(Palette.ink)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        .sheet(isPresented: $newTimer) { TimerEditor() }
    }.tint(Palette.red).preferredColorScheme(.light)
  }
}

struct TimerEditor: View {
  var existing: KitchenTimer?
  @EnvironmentObject private var store: KitchenStore
  @Environment(\.dismiss) private var dismiss
  @State private var name = ""
  @State private var minutes = 0
  @State private var seconds = 30

  var body: some View {
    NavigationStack {
      Form {
        Section("Name your timer") {
          TextField("e.g. Dressing", text: $name).accessibilityLabel("Timer name")
        }
        Section("Duration") {
          Stepper("\(minutes) minutes", value: $minutes, in: 0...180).accessibilityLabel(
            "Timer minutes")
          Stepper("\(seconds) seconds", value: $seconds, in: 0...59).accessibilityLabel(
            "Timer seconds")
        }
        Section {
          Button(existing == nil ? "Create & start timer" : "Save & restart timer") {
            let id = existing?.id ?? UUID().uuidString
            var timer = KitchenTimer(
              id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
              seconds: minutes * 60 + seconds)
            timer.start()
            store.state.timers[id] = timer
            dismiss()
          }.disabled(
            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || minutes * 60 + seconds == 0)
        } footer: {
          Text(
            "Changing the duration starts the full timer again. Timers do not send background notifications."
          )
        }
      }.navigationTitle(existing == nil ? "New timer" : "Adjust timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        .onAppear {
          if let existing {
            name = existing.name
            minutes = Int(existing.duration) / 60
            seconds = Int(existing.duration) % 60
          }
        }
    }.tint(Palette.red).preferredColorScheme(.light)
  }
}
