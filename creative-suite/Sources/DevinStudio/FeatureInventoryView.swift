import SwiftUI
import DevinCore

struct FeatureInventoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: StudioTool
    @State private var query = ""
    @State private var status = "All"
    var close: (() -> Void)?
    init(initialTool: StudioTool, close: (() -> Void)? = nil) { _selected = State(initialValue: initialTool); self.close = close }
    var features: [ParityFeature] { ParityLedger.features(selected).filter { (status == "All" || $0.status.rawValue == status) && (query.isEmpty || ($0.name + $0.category).localizedCaseInsensitiveContains(query)) } }
    var categories: [String] { var seen = Set<String>(); return features.compactMap { seen.insert($0.category).inserted ? $0.category : nil } }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Feature Parity Ledger").font(.system(size: 23, weight: .medium))
                    Text("A working control is not proof of feature parity.").font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Button("Done") { if let close { close() } else { dismiss() } }.buttonStyle(ProButtonStyle()).keyboardShortcut(.cancelAction)
            }.padding(20)
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    ForEach(StudioTool.allCases) { tool in
                        Button { selected = tool } label: {
                            HStack(spacing: 9) { ToolBadge(tool: tool, size: 26); Text(tool.name).font(.system(size: 11)); Spacer() }.padding(7).background(selected == tool ? Theme.elevated : .clear, in: RoundedRectangle(cornerRadius: 5))
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }.padding(12).frame(width: 190).background(Theme.sidebar)
                VStack(spacing: 0) {
                    HStack {
                        TextField("Search features", text: $query).textFieldStyle(.roundedBorder)
                        Picker("Status", selection: $status) { Text("All").tag("All"); ForEach(ParityStatus.allCases, id: \.self) { Text($0.title).tag($0.rawValue) } }.labelsHidden().frame(width: 215)
                    }.padding(15)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            let all = ParityLedger.features(selected)
                            Text("\(all.count) listed · \(all.filter { $0.status == .missing }.count) missing · \(all.filter { $0.status == .partial }.count) partial · \(all.filter { $0.status == .verified }.count) reference-verified").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "E5BB83"))
                            Text(ParityLedger.warning).font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(3)
                            DisclosureGroup("Scope and acceptance gates") {
                                Text(ParityLedger.scope).font(.system(size: 11)).padding(.vertical, 6)
                                ForEach(ParityLedger.gates, id: \.self) { Text($0).font(.system(size: 11)).padding(.vertical, 4).frame(maxWidth: .infinity, alignment: .leading) }
                            }.font(.system(size: 12))
                            ForEach(categories, id: \.self) { category in
                                Text(category.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(Theme.muted).padding(.top, 12)
                                ForEach(features.filter { $0.category == category }) { feature in
                                    DisclosureGroup {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(feature.limitation)
                                            if let url = URL(string: feature.reference) { Link("Reference documentation", destination: url) }
                                            if !feature.implementation.isEmpty { Text("Implementation evidence").bold(); ForEach(feature.implementation, id: \.self) { Text($0).font(.system(size: 10, design: .monospaced)).textSelection(.enabled) } }
                                            Text("Required verification").bold()
                                            ForEach(feature.acceptance, id: \.self) { Text($0) }
                                            Text(feature.comparisonEvidence.isEmpty ? "No differential reference evidence is recorded." : feature.comparisonEvidence.joined(separator: "\n")).foregroundStyle(Theme.muted)
                                        }.font(.system(size: 11)).padding(.vertical, 9)
                                    } label: {
                                        HStack { Text(feature.name).font(.system(size: 12)); Spacer(); Text(feature.status.title).font(.system(size: 9)).foregroundStyle(feature.status == .missing ? Theme.muted : Color(hex: "E5BB83")) }
                                    }.padding(8).background(Theme.panel, in: RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }.padding(.horizontal, 18).padding(.bottom, 20)
                    }
                }
            }
        }.frame(width: 960, height: 690).background(Theme.background).foregroundStyle(Theme.text).preferredColorScheme(.dark)
    }
}
