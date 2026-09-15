import SwiftUI
import DevinCore

struct DashboardView: View {
    @State private var search = ""
    @State private var category = "All apps"
    @State private var recents = RecentProjects.all
    var tools: [StudioTool] {
        StudioTool.allCases.filter { tool in
            (category == "All apps" || category == tool.category) && (search.isEmpty || (tool.name + tool.detail).localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Text("Your creative home").font(.system(size: 13, weight: .medium))
                    Spacer()
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                        TextField("Find your next tool", text: $search).textFieldStyle(.plain).font(.system(size: 12))
                        if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain) }
                    }.padding(10).frame(width: 230).background(Theme.panel, in: RoundedRectangle(cornerRadius: 7))
                    Button("Parity ledger") { AppCoordinator.shared.showFeatures() }.buttonStyle(StudioButtonStyle())
                    Button { AppCoordinator.shared.openDocument() } label: { Label("Open project", systemImage: "folder") }.buttonStyle(StudioButtonStyle())
                }.padding(.horizontal, 32).frame(height: 68).overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        hero
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("A whole world of making.").font(.system(size: 23, weight: .medium))
                                Text("Twelve focused tools. One place to bring it all together.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text("NATIVE TO MAC").font(.system(size: 9, weight: .semibold)).tracking(1.4)
                                .foregroundStyle(Theme.accent).padding(9).overlay(Capsule().stroke(Theme.accent.opacity(0.25)))
                        }
                        HStack(spacing: 7) {
                            ForEach(["All apps", "Design", "Photography", "Video & motion", "Audio"], id: \.self) { item in
                                Button { category = item } label: {
                                    Text(item).font(.system(size: 11, weight: .medium)).padding(.horizontal, 13).padding(.vertical, 8)
                                        .foregroundStyle(category == item ? Theme.text : Theme.muted)
                                        .background(category == item ? Theme.elevated : .clear, in: Capsule())
                                }.buttonStyle(.plain)
                            }
                            Spacer()
                            Text("\(tools.count) apps").font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }.padding(.top, -10)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(tools) { tool in ToolCard(tool: tool) { AppCoordinator.shared.launch(tool) } }
                        }.padding(.top, -16)
                        if tools.isEmpty {
                            Text("No apps match your search.").foregroundStyle(Theme.muted).padding(.vertical, 30)
                        }
                        recentSection
                        HStack {
                            Text("YOURS TO MAKE.").tracking(2)
                            Spacer()
                            Text("LOCAL FILES. NO ACCOUNT. NO SUBSCRIPTION.").tracking(1.2)
                        }.font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.muted.opacity(0.65)).padding(.vertical, 14)
                    }.padding(32)
                }
            }
        }.background(Theme.background).foregroundStyle(Theme.text).preferredColorScheme(.dark)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in recents = RecentProjects.all }
    }
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                DevinMark()
                VStack(alignment: .leading, spacing: 2) {
                    Text("devin").font(.system(size: 22, weight: .semibold, design: .rounded)).tracking(-0.8)
                    Text("CREATIVE STUDIO").font(.system(size: 8, weight: .medium)).tracking(1.9).foregroundStyle(Theme.muted)
                }
            }.padding(.top, 56).padding(.bottom, 30).padding(.leading, 22)
            Button { category = "All apps"; search = "" } label: {
                HStack(spacing: 12) { Image(systemName: "square.grid.2x2.fill"); Text("All applications"); Spacer(); Text("12").font(.system(size: 10, design: .monospaced)) }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.accent).padding(12)
                    .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
            }.buttonStyle(.plain).padding(.horizontal, 12)
            Text("YOUR TOOLKIT").font(.system(size: 9, weight: .semibold)).tracking(1.8).foregroundStyle(Theme.muted).padding(.leading, 24).padding(.top, 28).padding(.bottom, 12)
            ForEach(StudioTool.allCases) { tool in
                Button { AppCoordinator.shared.launch(tool) } label: {
                    HStack(spacing: 12) {
                        Text(tool.monogram).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color(hex: tool.color)).frame(width: 22)
                        Text(tool.name).font(.system(size: 12))
                        Spacer()
                    }.foregroundStyle(Theme.muted).padding(.horizontal, 24).frame(height: 35)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            Spacer(minLength: 26)
            VStack(alignment: .leading, spacing: 10) {
                HStack { Circle().fill(Theme.accent).frame(width: 5, height: 5); Text("Your workspace. Your rules.").font(.system(size: 10, weight: .medium)) }
                Text("An independent creative suite.\nBuilt for the way you think.").font(.system(size: 10)).lineSpacing(4).foregroundStyle(Theme.muted)
                Text("EARLY ACCESS  /  0.4.2").font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(Theme.muted.opacity(0.7))
            }.padding(22)
        }.frame(width: 218).background(Theme.sidebar).overlay(alignment: .trailing) { Rectangle().fill(Theme.line).frame(width: 1) }
    }
    var hero: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 17) {
                HStack(spacing: 8) { Rectangle().fill(Theme.accent).frame(width: 22, height: 1); Text("IDEAS START HERE").tracking(2) }
                    .font(.system(size: 9, weight: .semibold)).foregroundStyle(Theme.accent)
                Text("Make something\nonly you can.").font(.system(size: 46, weight: .medium)).tracking(-2).lineSpacing(-3)
                Text("From the first spark to the final frame.\nYour next great idea has a home.")
                    .font(.system(size: 12)).lineSpacing(5).foregroundStyle(Theme.muted)
                Button { AppCoordinator.shared.launch(.pixel) } label: {
                    HStack(spacing: 22) { Text("Create something new"); Image(systemName: "arrow.up.right") }
                }.buttonStyle(StudioButtonStyle(primary: true)).padding(.top, 3)
            }.padding(32).frame(maxWidth: .infinity, alignment: .leading)
            HeroArtwork().frame(width: 360).clipped()
        }.frame(height: 316).background(Color(hex: "20261F"), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
    }
    var recentSection: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text("Pick up where you left off.").font(.system(size: 19, weight: .medium))
                Spacer()
                Button("Open a project…") { AppCoordinator.shared.openDocument() }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(Theme.accent)
            }
            if recents.isEmpty {
                HStack(spacing: 18) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 23, weight: .light)).foregroundStyle(Theme.muted)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("A fresh canvas.").font(.system(size: 12, weight: .medium))
                        Text("Your saved projects will appear here. Open any app to begin.").font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }.padding(22).frame(maxWidth: .infinity).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(recents.prefix(5)) { recent in
                    Button { AppCoordinator.shared.openProject(recent.url) } label: {
                        HStack(spacing: 14) {
                            ToolBadge(tool: recent.tool, size: 34)
                            VStack(alignment: .leading, spacing: 4) { Text(recent.title).font(.system(size: 12, weight: .medium)); Text(recent.tool.name).font(.system(size: 10)).foregroundStyle(Theme.muted) }
                            Spacer()
                            Text(recent.date, style: .relative).font(.system(size: 10)).foregroundStyle(Theme.muted)
                            Image(systemName: "arrow.up.right").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        }.padding(13).background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct ToolCard: View {
    let tool: StudioTool
    let action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ToolBadge(tool: tool)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 12)).foregroundStyle(hovering ? Color(hex: tool.color) : Theme.muted.opacity(0.5))
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text(tool.name).font(.system(size: 16, weight: .medium))
                    Text(tool.detail).font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(3).fixedSize(horizontal: false, vertical: true).frame(height: 32, alignment: .top)
                }
                HStack { Text(tool.category.uppercased()).font(.system(size: 8, weight: .medium)).tracking(1.1); Spacer(); Text("Open").font(.system(size: 10, weight: .medium)).foregroundStyle(Color(hex: tool.color)) }
                    .foregroundStyle(Theme.muted.opacity(0.8))
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(hovering ? Theme.elevated : Theme.panel, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(hovering ? Color(hex: tool.color).opacity(0.3) : Theme.line))
                .contentShape(RoundedRectangle(cornerRadius: 11))
        }.buttonStyle(.plain).onHover { hovering = $0 }.animation(.easeOut(duration: 0.15), value: hovering)
    }
}

struct HeroArtwork: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "2A3428")
                ForEach(0..<11) { i in
                    Circle().stroke(Color(hex: "C7DEA2").opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(90 + i * 42), height: CGFloat(90 + i * 42))
                        .offset(x: 40, y: 0)
                }
                Ellipse().fill(Color.black.opacity(0.35)).frame(width: 210, height: 35).blur(radius: 18).offset(x: 8, y: 101)
                RoundedRectangle(cornerRadius: 40)
                    .fill(LinearGradient(colors: [Color(hex: "E3ECBC"), Color(hex: "ABCB7A"), Color(hex: "73994C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 175, height: 220).rotationEffect(.degrees(-26)).offset(x: -30, y: 8)
                    .shadow(color: .black.opacity(0.2), radius: 16, x: 10, y: 16)
                RoundedRectangle(cornerRadius: 37)
                    .fill(LinearGradient(colors: [Color(hex: "EFB897"), Color(hex: "CE8764"), Color(hex: "8C503C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 150, height: 210).rotationEffect(.degrees(24)).offset(x: 65, y: -14)
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 10, y: 12)
                Text("d").font(.system(size: 205, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: "233420")).rotationEffect(.degrees(-26)).offset(x: -28, y: -4)
                Circle().fill(Color(hex: "E9ECCF")).frame(width: 64, height: 64).offset(x: 104, y: 77).shadow(color: .black.opacity(0.2), radius: 10, x: 4, y: 8)
                VStack { HStack { Spacer(); Text("PLAY IS A PRACTICE.").tracking(1.5).font(.system(size: 8, weight: .medium)).foregroundStyle(Color(hex: "D6DFC1")) }; Spacer(); HStack { Text("STUDY NO. 001").tracking(1.4).font(.system(size: 8, design: .monospaced)); Spacer(); Image(systemName: "plus").font(.system(size: 14, weight: .ultraLight)) }.foregroundStyle(Color(hex: "C2D0AF")) }.padding(22)
            }.frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
