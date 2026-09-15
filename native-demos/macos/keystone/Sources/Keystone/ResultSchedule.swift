import KeystoneCore
import SwiftUI

struct ResultSchedule: View {
  @EnvironmentObject var studio: Studio
  @State private var kind = "Members"
  @State private var filter = "All"
  @State private var order = "Demand"
  @State private var selectedMember: Int?
  @State private var selectedNode: Int?

  private var members: [Member] {
    let filtered = studio.design.members.filter { member in
      let r = studio.result?.members[member.id]
      switch filter {
      case "Compression": return (r?.forceKN ?? 0) < -0.001
      case "Tension": return (r?.forceKN ?? 0) > 0.001
      case "Over limit": return (r?.capacityUtilization ?? 0) > 1
      default: return true
      }
    }
    return filtered.sorted {
      if order == "Demand" {
        let a = studio.result?.members[$0.id]?.capacityUtilization ?? 0
        let b = studio.result?.members[$1.id]?.capacityUtilization ?? 0
        if abs(a - b) > 1e-10 { return a > b }
      }
      if order == "Length", studio.design.length($0) != studio.design.length($1) {
        return studio.design.length($0) > studio.design.length($1)
      }
      return $0.id < $1.id
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Eyebrow(text: "RESULTS / \(studio.design.activeCase.name.uppercased())")
        HStack {
          Text("The member ledger").font(.system(size: 29, design: .serif))
          Spacer()
          Button(action: studio.exportCSV) {
            Label("CSV", systemImage: "arrow.up.right").font(.system(size: 11)).foregroundStyle(
              Ink.copper)
          }.accessibilityLabel("Export schedule CSV")
        }
        Text("Select a row to inspect and edit its properties. Forces: tension + / compression −.")
          .font(.system(size: 11)).foregroundStyle(Ink.muted)
      }.padding(.top, 7)
      HStack {
        Picker("Schedule", selection: $kind) {
          Text("Members").tag("Members")
          Text("Joints & reactions").tag("Joints")
        }.pickerStyle(.segmented).frame(maxWidth: 280)
        Spacer(minLength: 5)
        if kind == "Members" {
          Picker("Sort", selection: $order) {
            ForEach(["Demand", "ID", "Length"], id: \.self) { Text($0).tag($0) }
          }.frame(width: 133).font(.system(size: 11))
        }
      }
      if kind == "Members" {
        HStack {
          ForEach(["All", "Compression", "Tension", "Over limit"], id: \.self) { name in
            Button {
              filter = name
            } label: {
              Text(name).font(.system(size: 10)).padding(.horizontal, 10).padding(.vertical, 6)
                .background(filter == name ? Ink.navy : Ink.line.opacity(0.3), in: Capsule())
                .foregroundStyle(filter == name ? .white : Ink.muted)
            }.accessibilityLabel("Filter \(name)")
          }
          Spacer()
          Text("\(members.count) members").font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Ink.muted)
        }
        memberTable
        if members.isEmpty {
          Text("No members match this filter.").font(.system(size: 12)).foregroundStyle(Ink.muted)
        }
      } else {
        nodeTable
      }
      Text(
        studio.result == nil
          ? (studio.analysisError
            ?? "Geometry schedule · run analysis to compute forces and reactions.")
          : "* Asterisk: compression buckling unchecked; ratio shows axial yield only. Criteria apply to this case only."
      )
      .font(.system(size: 10)).foregroundStyle(Ink.muted).lineSpacing(3)
      .fixedSize(horizontal: false, vertical: true)
    }.padding(22).frame(maxWidth: .infinity, maxHeight: .infinity)
      .onChange(of: selectedMember) { _, id in if let id { studio.selection = .member(id) } }
      .onChange(of: selectedNode) { _, id in if let id { studio.selection = .node(id) } }
  }

  private var memberTable: some View {
    Table(members, selection: $selectedMember) {
      TableColumn("Member") { member in
        VStack(alignment: .leading, spacing: 3) {
          Text("M\(member.id + 1)").fontWeight(.semibold)
          Text("N\(member.a + 1)–N\(member.b + 1)").font(.system(size: 9)).foregroundStyle(
            Ink.muted)
        }.padding(.vertical, 4)
      }.width(min: 60, ideal: 72)
      TableColumn("L · m") { member in Text(String(format: "%.2f", studio.design.length(member))) }
        .width(min: 43, ideal: 55)
      TableColumn("A · cm²") { member in Text(String(format: "%.2f", member.areaCM2)) }.width(
        min: 53, ideal: 65)
      TableColumn("N · kN") { member in
        Text(studio.result?.members[member.id].map { String(format: "%+.2f", $0.forceKN) } ?? "—")
          .foregroundStyle(
            (studio.result?.members[member.id]?.forceKN ?? 0) < 0 ? Ink.blue : Ink.copper)
      }.width(min: 63, ideal: 80)
      TableColumn("σ · MPa") { member in
        Text(studio.result?.members[member.id].map { String(format: "%+.2f", $0.stressMPa) } ?? "—")
      }.width(min: 65, ideal: 80)
      TableColumn("D / C") { member in
        if let r = studio.result?.members[member.id] {
          HStack(spacing: 5) {
            Circle().fill(
              r.capacityUtilization > 1 || (r.forceKN < -0.001 && member.inertiaCM4 == nil)
                ? Ink.copper : Ink.green
            )
            .frame(width: 5, height: 5)
            Text(
              String(format: "%.1f%%", r.capacityUtilization * 100)
                + (r.forceKN < -0.001 && member.inertiaCM4 == nil ? "*" : ""))
          }
        } else {
          Text("—")
        }
      }.width(min: 78, ideal: 92)
    }.font(.system(size: 11, design: .monospaced)).tableStyle(
      .inset(alternatesRowBackgrounds: true)
    )
    .frame(minHeight: 120).accessibilityLabel("Member schedule")
  }

  private var nodeTable: some View {
    Table(studio.design.nodes, selection: $selectedNode) {
      TableColumn("Joint") { node in
        VStack(alignment: .leading, spacing: 3) {
          Text("N\(node.id + 1)").fontWeight(.semibold)
          Text(node.support == .pin ? "Pin" : (node.support == .roller ? "Roller" : "Free"))
            .font(.system(size: 9)).foregroundStyle(Ink.muted)
        }.padding(.vertical, 4)
      }.width(min: 55, ideal: 60)
      TableColumn("Fx · kN") { node in loadValue(node.id, axis: 0) }.width(min: 65, ideal: 73)
      TableColumn("Fy · kN") { node in loadValue(node.id, axis: 1) }.width(min: 65, ideal: 73)
      TableColumn("Δy · mm") { node in
        Text(
          studio.result?.displacement[node.id].map { String(format: "%+.3f", $0.y * 1000) } ?? "—")
      }.width(min: 73, ideal: 85)
      TableColumn("Rx · kN") { node in reactionValue(node.id, axis: 0) }.width(min: 65, ideal: 73)
      TableColumn("Ry · kN") { node in reactionValue(node.id, axis: 1) }.width(min: 65, ideal: 73)
    }.font(.system(size: 11, design: .monospaced)).tableStyle(
      .inset(alternatesRowBackgrounds: true)
    )
    .frame(minHeight: 120).accessibilityLabel("Joint and reaction schedule")
  }

  private func loadValue(_ id: Int, axis: Int) -> some View {
    Text(String(format: "%+.2f", studio.design.effectiveLoads()[id]?[axis] ?? 0))
  }
  private func reactionValue(_ id: Int, axis: Int) -> some View {
    Text(studio.result?.reactionsKN[id].map { String(format: "%+.2f", $0[axis]) } ?? "—")
  }
}
