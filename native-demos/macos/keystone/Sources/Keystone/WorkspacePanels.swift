import KeystoneCore
import SwiftUI

struct Eyebrow: View {
  var text: String
  var body: some View {
    Text(text).font(.system(size: 9, weight: .semibold)).tracking(1.1).foregroundStyle(Ink.muted)
  }
}

struct InfoRow: View {
  var title: String
  var value: String
  var body: some View {
    HStack {
      Text(title).foregroundStyle(Ink.muted)
      Spacer()
      Text(value).font(.system(size: 11, weight: .medium, design: .monospaced)).monospacedDigit()
    }.font(.system(size: 11))
  }
}

struct NumberEntry: View {
  @EnvironmentObject var studio: Studio
  var title: String
  var value: Double
  var unit: String
  var range: ClosedRange<Double>
  var fieldWidth: CGFloat = 82
  var onCommit: (Double) -> Void
  @State private var text = ""
  @State private var invalid = false
  @State private var editID = UUID()
  @FocusState private var focused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 7) {
        Text(title).font(.system(size: 11)).foregroundStyle(Ink.muted)
          .fixedSize(horizontal: true, vertical: false)
        Spacer(minLength: 4)
        TextField(title, text: Binding(get: { text }, set: { stage($0) }))
          .textFieldStyle(.plain).multilineTextAlignment(.trailing)
          .font(.system(size: 11, design: .monospaced)).foregroundStyle(Ink.navy)
          .padding(.horizontal, 8).padding(.vertical, 7).frame(width: fieldWidth)
          .background(.white, in: RoundedRectangle(cornerRadius: 4))
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(invalid ? Ink.copper : Ink.line))
          .focused($focused).onSubmit {
            studio.commitPendingEdits()
            focused = false
          }
          .onChange(of: focused) { _, active in if !active { studio.commitPendingEdits() } }
          .accessibilityLabel(title).help(
            "Enter \(range.lowerBound)…\(range.upperBound) \(unit); Return to apply")
        Text(unit).font(.system(size: 10)).foregroundStyle(Ink.muted).frame(
          minWidth: 20, alignment: .leading)
      }
      if invalid {
        Text(
          "Use \(String(format: "%g", range.lowerBound))–\(String(format: "%g", range.upperBound)); unchanged."
        )
        .font(.system(size: 9)).foregroundStyle(Ink.copper)
      }
    }
    .onAppear { text = String(format: "%g", value) }
    .onChange(of: value) { _, new in
      text = String(format: "%g", new)
      invalid = false
    }
    .onDisappear { studio.commitPendingEdits() }
  }

  private func stage(_ input: String) {
    text = input
    guard let number = Double(input), number.isFinite, range.contains(number) else {
      invalid = true
      studio.stageEdit(editID, nil)
      return
    }
    invalid = false
    studio.stageEdit(editID, number == value ? nil : { onCommit(number) })
  }
}

struct CaseEditor: View {
  @EnvironmentObject var studio: Studio
  @State private var name = ""
  @State private var editID = UUID()
  @FocusState private var nameFocused: Bool

  var body: some View {
    let caseID = studio.design.activeCaseID
    VStack(alignment: .leading, spacing: 10) {
      TextField("Case name", text: Binding(get: { name }, set: { stageName($0, caseID) }))
        .textFieldStyle(.plain)
        .font(.system(size: 11, weight: .medium)).foregroundStyle(Ink.navy)
        .padding(8).background(.white, in: RoundedRectangle(cornerRadius: 4))
        .focused($nameFocused).onSubmit {
          studio.commitPendingEdits()
          nameFocused = false
        }
        .onChange(of: nameFocused) { _, active in if !active { studio.commitPendingEdits() } }
        .accessibilityLabel("Case name")
      NumberEntry(
        title: "Factor", value: studio.design.activeCase.factor, unit: "×", range: 0.01...10,
        fieldWidth: 60
      ) { value in
        studio.updateCase(id: caseID) { $0.factor = value }
      }
      Toggle(
        "Include self-weight",
        isOn: Binding(
          get: { studio.design.activeCase.includesSelfWeight },
          set: { value in studio.updateCase { $0.includesSelfWeight = value } }
        )
      ).toggleStyle(.checkbox).font(.system(size: 11)).foregroundStyle(Ink.navy)
      Text("Factor applies to nodal loads and member self-weight.")
        .font(.system(size: 9)).foregroundStyle(Ink.muted).fixedSize(
          horizontal: false, vertical: true)
    }.padding(10).background(Ink.paper, in: RoundedRectangle(cornerRadius: 5))
      .onAppear { name = studio.design.activeCase.name }
      .onChange(of: studio.design.activeCase.name) { _, value in name = value }
      .onDisappear { studio.commitPendingEdits() }
  }

  private func stageName(_ input: String, _ caseID: String) {
    name = input
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      studio.stageEdit(editID, nil)
      return
    }
    studio.stageEdit(editID) { studio.updateCase(id: caseID) { $0.name = trimmed } }
  }
}

struct SelectionInspector: View {
  @EnvironmentObject var studio: Studio
  var body: some View {
    Group {
      if let member = studio.selectedMember {
        memberPanel(member).id("member-\(member.id)")
      } else if let node = studio.selectedNode {
        nodePanel(node).id("node-\(node.id)-\(studio.design.activeCaseID)")
      } else {
        VStack(alignment: .leading, spacing: 13) {
          Eyebrow(text: "MODEL INSPECTOR")
          Text("A considered\nconnection.").font(.system(size: 24, design: .serif)).lineSpacing(2)
          Text(
            "Select a member for section properties, or a joint for precise coordinates and case loads."
          )
          .font(.system(size: 11)).foregroundStyle(Ink.muted).lineSpacing(4)
          InfoRow(title: "Span", value: String(format: "%.2f m", studio.design.spanM))
          InfoRow(
            title: "Total Fy",
            value: String(
              format: "%+.2f kN", studio.design.effectiveLoads().values.reduce(0) { $0 + $1.y }))
        }
      }
    }
  }

  private func memberPanel(_ member: Member) -> some View {
    VStack(alignment: .leading, spacing: 13) {
      Eyebrow(text: "MEMBER / M\(member.id + 1)")
      HStack(alignment: .center, spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 3).stroke(Ink.navy, lineWidth: 7).frame(
            width: 43, height: 43)
          if member.inertiaCM4 == nil { Text("?").font(.system(size: 17, design: .serif)) }
        }.frame(width: 55, height: 60)
        VStack(alignment: .leading, spacing: 5) {
          Text(member.sectionName ?? "Custom section").font(.system(size: 13, weight: .semibold))
          Text("N\(member.a + 1) → N\(member.b + 1)").font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Ink.muted)
        }
      }
      InfoRow(title: "Length", value: String(format: "%.3f m", studio.design.length(member)))
      Menu {
        ForEach(SectionPreset.catalog) { section in
          Button(section.name) { studio.applySection(section, all: false) }
        }
      } label: {
        Label("Choose section", systemImage: "square.on.square").font(.system(size: 11))
          .foregroundStyle(Ink.copper).frame(maxWidth: .infinity, alignment: .leading)
          .padding(10).background(Ink.line.opacity(0.25), in: RoundedRectangle(cornerRadius: 4))
      }.menuStyle(.borderlessButton)
      NumberEntry(title: "Area", value: member.areaCM2, unit: "cm²", range: 0.1...1000) {
        studio.setArea(member.id, area: $0)
      }
      NumberEntry(
        title: "Min. inertia", value: member.inertiaCM4 ?? 0, unit: "cm⁴", range: 0...1_000_000
      ) { value in
        studio.setMember(member.id) {
          $0.inertiaCM4 = value == 0 ? nil : value
          $0.sectionName = nil
        }
      }
      NumberEntry(
        title: "Length factor K", value: member.effectiveLengthFactor, unit: "×", range: 0.5...3
      ) { value in
        studio.setMember(member.id) { $0.effectiveLengthFactor = value }
      }
      Text(
        member.inertiaCM4 == nil
          ? "I = 0 means buckling is unchecked. Choose a section or enter its least inertia."
          : "Ideal section properties. K=1 assumes pin-ended buckling over the full member length."
      )
      .font(.system(size: 9)).foregroundStyle(Ink.muted).lineSpacing(3)
      if let r = studio.result?.members[member.id] {
        Divider()
        InfoRow(title: "Axial force", value: String(format: "%+.2f kN", r.forceKN))
        InfoRow(title: "Stress", value: String(format: "%+.2f MPa", r.stressMPa))
        InfoRow(
          title: "Demand / capacity", value: String(format: "%.1f%%", r.capacityUtilization * 100))
        if r.forceKN < -0.001 {
          InfoRow(
            title: "Euler Pcr",
            value: r.eulerCriticalKN.map { String(format: "%.1f kN", $0) } ?? "Unchecked")
        }
        Text(
          r.forceKN < -0.001 && member.inertiaCM4 == nil
            ? "YIELD ONLY · BUCKLING UNCHECKED" : r.governingMode.uppercased()
        )
        .font(.system(size: 9, weight: .semibold)).foregroundStyle(Ink.copper)
      }
      removeButton("Remove member")
    }
  }

  private func nodePanel(_ node: Node) -> some View {
    let load = studio.design.nodalLoad(node.id)
    let caseID = studio.design.activeCaseID
    return VStack(alignment: .leading, spacing: 13) {
      Eyebrow(text: "JOINT / N\(node.id + 1)")
      Text("N\(node.id + 1)").font(.system(size: 30, design: .serif))
      NumberEntry(title: "X coordinate", value: node.x, unit: "m", range: -100...100) { value in
        studio.setNode(node.id) { $0.x = value }
      }
      NumberEntry(title: "Y coordinate", value: node.y, unit: "m", range: -100...100) { value in
        studio.setNode(node.id) { $0.y = value }
      }
      Picker(
        "Support",
        selection: Binding(
          get: { node.support }, set: { value in studio.setNode(node.id) { $0.support = value } }
        )
      ) {
        ForEach(Support.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }.font(.system(size: 11))
      Divider()
      Eyebrow(text: "UNFACTORED CASE LOAD")
      NumberEntry(title: "Horizontal →", value: load.xKN, unit: "kN", range: -10000...10000) {
        value in
        var next = load
        next.xKN = value
        studio.setLoad(next, caseID: caseID)
      }
      NumberEntry(title: "Vertical ↓", value: load.downKN, unit: "kN", range: -10000...10000) {
        value in
        var next = load
        next.downKN = value
        studio.setLoad(next, caseID: caseID)
      }
      Text("Negative values act left / upward.\nSelf-weight is added by the solver.")
        .font(.system(size: 9)).foregroundStyle(Ink.muted).lineSpacing(3)
      if load.xKN != 0 || load.downKN != 0 {
        Button("Clear case load") {
          studio.setLoad(NodalLoad(nodeID: node.id), caseID: caseID)
        }
        .font(.system(size: 11)).foregroundStyle(Ink.copper)
      }
      if let d = studio.result?.displacement[node.id] {
        InfoRow(title: "Δx / Δy", value: String(format: "%.2f / %.2f mm", d.x * 1000, d.y * 1000))
      }
      if let r = studio.result?.reactionsKN[node.id], node.support != .free {
        InfoRow(title: "Rx / Ry", value: String(format: "%.2f / %.2f kN", r.x, r.y))
      }
      removeButton("Remove joint")
    }
  }

  private func removeButton(_ title: String) -> some View {
    Button(action: studio.deleteSelection) {
      Label(title, systemImage: "trash").font(.system(size: 11)).foregroundStyle(Ink.copper)
        .padding(.vertical, 6)
    }
  }
}

struct MaterialInspector: View {
  @EnvironmentObject var studio: Studio
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Eyebrow(text: "MATERIAL & SECTIONS")
      Picker(
        "Material",
        selection: Binding(
          get: { studio.design.material.name },
          set: { name in
            studio.change { $0.material = name == Material.steel.name ? .steel : .aluminum }
          }
        )
      ) {
        Text("Steel · 200 GPa").tag(Material.steel.name)
        Text("Aluminum · 69 GPa").tag(Material.aluminum.name)
        if studio.design.material.name != Material.steel.name
          && studio.design.material.name != Material.aluminum.name
        {
          Text(studio.design.material.name).tag(studio.design.material.name)
        }
      }.labelsHidden().font(.system(size: 11))
      InfoRow(title: "Total mass", value: String(format: "%.1f kg", studio.design.massKg))
      NumberEntry(title: "Budget", value: studio.design.budget, unit: "$", range: 1...1_000_000) {
        value in
        studio.change { $0.budget = value }
      }
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(Ink.line)
          Capsule().fill(studio.design.cost > studio.design.budget ? Ink.copper : Ink.green)
            .frame(width: geometry.size.width * min(1, studio.design.cost / studio.design.budget))
        }
      }.frame(height: 4)
      Menu {
        ForEach(SectionPreset.catalog) { section in
          Button(section.name) { studio.applySection(section, all: true) }
        }
      } label: {
        Label("Assign section to all", systemImage: "square.stack.3d.up")
          .font(.system(size: 11, weight: .medium)).foregroundStyle(Ink.copper).padding(
            .vertical, 9)
      }.menuStyle(.borderlessButton)
      Text("SHS: ideal square hollow section.\nSharp corners; no manufacturer tolerances.")
        .font(.system(size: 9)).foregroundStyle(Ink.muted).lineSpacing(3)
    }
  }
}

struct StudyChecks: View {
  @EnvironmentObject var studio: Studio
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Eyebrow(text: "ACTIVE CASE / STUDY CHECKS")
      if let result = studio.result {
        check(
          "Member resistance", value: String(format: "%.1f%%", result.maxCapacityUtilization * 100),
          detail: result.missingBucklingChecks > 0
            ? "\(result.missingBucklingChecks) compression members have no inertia. Buckling is unchecked."
            : "Axial yield and Euler screening at γ = \(String(format: "%g", studio.design.resistanceFactor)).",
          status: result.missingBucklingChecks > 0
            ? "Incomplete" : (result.maxCapacityUtilization <= 1 ? "Within limit" : "Over limit"),
          good: result.missingBucklingChecks == 0 && result.maxCapacityUtilization <= 1)
        check(
          "Vertical deflection", value: String(format: "%.2f mm", result.maxVerticalMM),
          detail: String(
            format: "Limit %.2f mm · horizontal model extent / %.0f",
            studio.design.allowedVerticalMM, studio.design.deflectionRatio),
          status: studio.design.spanM <= 0
            ? "No horizontal span"
            : (result.maxVerticalMM <= studio.design.allowedVerticalMM
              ? "Within limit" : "Over limit"),
          good: studio.design.spanM > 0 && result.maxVerticalMM <= studio.design.allowedVerticalMM)
        check(
          "Material budget", value: String(format: "$%.0f", studio.design.cost),
          detail: String(format: "$%.0f target · raw material only", studio.design.budget),
          status: studio.design.cost <= studio.design.budget ? "Within budget" : "Over budget",
          good: studio.design.cost <= studio.design.budget)
        InfoRow(title: "Equilibrium residual", value: String(format: "%.2e N", result.residualN))
      } else {
        Text(studio.analysisError ?? "Run analysis to evaluate the active case.")
          .font(.system(size: 12)).foregroundStyle(Ink.muted).lineSpacing(4)
      }
      Divider()
      Eyebrow(text: "USER-DEFINED CRITERIA")
      NumberEntry(
        title: "Resistance γ", value: studio.design.resistanceFactor, unit: "×", range: 1...5
      ) { value in
        studio.change { $0.resistanceFactor = value }
      }
      NumberEntry(
        title: "Deflection L /", value: studio.design.deflectionRatio, unit: "", range: 50...2000
      ) { value in
        studio.change { $0.deflectionRatio = value }
      }
      Text(
        "Demand/capacity = |N| × γ / min(Afy, π²EI/(KL)²) in compression; yield in tension. Cases are checked individually, not combined or enveloped."
      )
      .font(.system(size: 10)).foregroundStyle(Ink.muted).lineSpacing(4)
      if let baseline = studio.baselineMM, let result = studio.result, baseline > 1e-8 {
        Divider()
        Eyebrow(text: "STIFFNESS COMPARISON")
        Text(String(format: "%+.1f%%", (1 - result.maxDisplacementMM / baseline) * 100))
          .font(.system(size: 28, weight: .light, design: .rounded)).foregroundStyle(Ink.green)
        Text("Displacement reduction from reference.\nChanging case loads resets this comparison.")
          .font(.system(size: 10)).foregroundStyle(Ink.muted).lineSpacing(3)
        Button("Use current as reference") { studio.baselineMM = result.maxDisplacementMM }
          .font(.system(size: 11)).foregroundStyle(Ink.copper)
      }
      MaterialInspector()
    }
  }

  private func check(_ title: String, value: String, detail: String, status: String, good: Bool)
    -> some View
  {
    VStack(alignment: .leading, spacing: 9) {
      HStack {
        Text(title).font(.system(size: 11, weight: .medium))
        Spacer()
        Circle().fill(good ? Ink.green : Ink.copper).frame(width: 6, height: 6)
      }
      Text(value).font(.system(size: 25, weight: .light, design: .rounded)).monospacedDigit()
      Text(status.uppercased()).font(.system(size: 9, weight: .semibold)).tracking(0.6)
        .foregroundStyle(good ? Ink.green : Ink.copper)
      Text(detail).font(.system(size: 10)).foregroundStyle(Ink.muted).lineSpacing(3)
    }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
      .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(Ink.line.opacity(0.7)))
  }
}

struct ProjectDetails: View {
  @EnvironmentObject var studio: Studio
  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @State private var note = ""
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Eyebrow(text: "PROJECT / DETAILS")
      Text("Give your study context.").font(.system(size: 28, design: .serif))
      TextField("Project name", text: $title).textFieldStyle(.roundedBorder).accessibilityLabel(
        "Project name")
      Text("Design notes").font(.system(size: 12, weight: .medium))
      TextEditor(text: $note).font(.system(size: 13)).frame(height: 130)
        .padding(5).overlay(RoundedRectangle(cornerRadius: 5).stroke(Ink.line)).accessibilityLabel(
          "Design notes")
      Text(
        "Name: 1–120 characters. Notes: up to 2,000 characters. Included in the engineering report."
      )
      .font(.system(size: 10)).foregroundStyle(Ink.muted)
      HStack {
        Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        Spacer()
        Button("Save details") {
          studio.change {
            $0.name = title.trimmingCharacters(in: .whitespacesAndNewlines)
            $0.projectNote = note
          }
          dismiss()
        }.buttonStyle(.borderedProminent).tint(Ink.copper).keyboardShortcut(.defaultAction)
          .disabled(
            title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || title.count > 120
              || note.count > 2000)
      }
    }.padding(30).frame(width: 470).background(Ink.paper).foregroundStyle(Ink.navy)
      .onAppear {
        title = studio.design.name
        note = studio.design.projectNote
      }
  }
}
