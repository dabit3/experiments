import SwiftUI
import WebKit
import DevinCore

struct NativeCodeEditor: NSViewRepresentable {
    @Binding var text: String
    let language: String
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.autohidesScrollers = true
        let editor = NSTextView(frame: .zero)
        editor.delegate = context.coordinator
        editor.isRichText = false; editor.isAutomaticQuoteSubstitutionEnabled = false; editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticSpellingCorrectionEnabled = false; editor.isContinuousSpellCheckingEnabled = false
        editor.isAutomaticTextReplacementEnabled = false; editor.isGrammarCheckingEnabled = false
        editor.allowsUndo = true; editor.usesFindBar = true
        editor.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        editor.backgroundColor = NSColor(hex: "171B18"); editor.textColor = NSColor(hex: "DDE4D8")
        editor.insertionPointColor = NSColor(hex: "B5E7C9"); editor.textContainerInset = NSSize(width: 22, height: 22)
        editor.isVerticallyResizable = true; editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.minSize = NSSize(width: 0, height: 0); editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.string = text
        scroll.documentView = editor
        context.coordinator.highlight(editor)
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let editor = scroll.documentView as? NSTextView else { return }
        if editor.string != text {
            let selection = editor.selectedRange()
            editor.string = text
            editor.setSelectedRange(NSRange(location: min(selection.location, (text as NSString).length), length: 0))
            context.coordinator.highlight(editor)
        }
    }
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeCodeEditor
        init(_ parent: NativeCodeEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            parent.text = view.string
            highlight(view)
        }
        func highlight(_ view: NSTextView) {
            guard let storage = view.textStorage else { return }
            let text = view.string, range = NSRange(location: 0, length: (text as NSString).length)
            storage.beginEditing()
            storage.setAttributes([.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), .foregroundColor: NSColor(hex: "DDE4D8")], range: range)
            let patterns: [(String, String)] = [("</?[A-Za-z][^>]*>", "B5E7C9"), ("\\b(const|let|var|function|return|if|else|document|window|addEventListener|true|false|null)\\b", "C5B5EF"), ("[\\\"'][^\\\"'\\n]*[\\\"']", "E5BC91"), ("#[a-fA-F0-9]{3,8}\\b|\\b[0-9]+(px|vh|vw|rem|em|%)?", "9ECBE6")]
            for (pattern, color) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                for match in regex.matches(in: text, range: range) { storage.addAttribute(.foregroundColor, value: NSColor(hex: color), range: match.range) }
            }
            storage.endEditing()
        }
    }
}

struct WebPreview: NSViewRepresentable {
    let source: String
    var reloadToken = 0
    var onConsole: ((String) -> Void)?
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.userContentController.add(context.coordinator, name: "devinConsole")
        let script = """
        (() => {
          let remaining = 200;
          const send = (level, values) => {
            if (remaining-- <= 0) return;
            const text = values.map(value => { try { return typeof value === 'string' ? value : JSON.stringify(value); } catch (_) { return String(value); } }).join(' ');
            window.webkit.messageHandlers.devinConsole.postMessage(('[' + level + '] ' + text).slice(0, 2000));
          };
          ['log', 'warn', 'error'].forEach(level => { const original = console[level].bind(console); console[level] = (...values) => { send(level, values); original(...values); }; });
          window.addEventListener('error', event => send('error', [event.message]));
          window.addEventListener('unhandledrejection', event => send('error', [String(event.reason)]));
        })();
        """
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.setValue(false, forKey: "drawsBackground")
        context.coordinator.lastSource = source; context.coordinator.lastToken = reloadToken
        view.loadHTMLString(source, baseURL: URL(string: "https://preview.devin.invalid"))
        return view
    }
    func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.onConsole = onConsole
        if context.coordinator.lastSource != source || context.coordinator.lastToken != reloadToken {
            context.coordinator.lastSource = source; context.coordinator.lastToken = reloadToken
            view.loadHTMLString(source, baseURL: URL(string: "https://preview.devin.invalid"))
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(onConsole) }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var lastSource = ""
        var lastToken = 0
        var onConsole: ((String) -> Void)?
        init(_ onConsole: ((String) -> Void)?) { self.onConsole = onConsole }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let text = message.body as? String { onConsole?(String(text.prefix(2000))) }
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { onConsole?("[error] The preview process stopped. Select Run to reload it.") }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { onConsole?("[error] " + error.localizedDescription) }
    }
}

struct CodeWorkspace: View {
    @ObservedObject var session: StudioSession
    private var language: String { get { session.codeLanguage } nonmutating set { session.codeLanguage = newValue } }
    @State private var console: [String] = []
    @State private var showConsole = false
    @State private var reloadToken = 0
    @State private var live = true
    @State private var preview = ""
    @State private var viewport = "Responsive"
    var source: String { session.document.webSource() }
    var textBinding: Binding<String> {
        Binding(get: {
            switch language { case "CSS": return session.document.css; case "JavaScript": return session.document.javascript; default: return session.document.html }
        }, set: { text in
            session.mutate { d in switch language { case "CSS": d.css = text; case "JavaScript": d.javascript = text; default: d.html = text } }
        })
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left.forwardslash.chevron.right").foregroundStyle(Theme.accent)
                Text("WORKSPACE").font(.system(size: 9, weight: .semibold)).tracking(1.6).foregroundStyle(Theme.muted)
                Spacer()
                Toggle("Live preview", isOn: $live).toggleStyle(.switch).controlSize(.mini).font(.system(size: 11))
                Button("Console (\(console.count))") { showConsole.toggle() }.buttonStyle(StudioButtonStyle())
                Button { preview = source; reloadToken += 1; console = [] } label: { Label("Run", systemImage: "play.fill") }.buttonStyle(StudioButtonStyle(primary: true))
                Picker("Viewport", selection: $viewport) { Text("Responsive").tag("Responsive"); Text("Tablet · 768").tag("Tablet"); Text("Mobile · 390").tag("Mobile") }.frame(width: 165)
            }.padding(.horizontal, 20).frame(height: 48).background(Theme.sidebar)
            HSplitView {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(["HTML", "CSS", "JavaScript"], id: \.self) { type in
                            Button { language = type } label: {
                                HStack(spacing: 8) { Circle().fill(type == "HTML" ? Color(hex: "E6AB8C") : type == "CSS" ? Color(hex: "A9C5EF") : Color(hex: "E5D396")).frame(width: 6, height: 6); Text(type == "HTML" ? "index.html" : type == "CSS" ? "style.css" : "script.js").font(.system(size: 11)) }
                                    .padding(.horizontal, 17).frame(height: 41).background(language == type ? Color(hex: "171B18") : Theme.background)
                                    .overlay(alignment: .top) { if language == type { Rectangle().fill(Theme.accent).frame(height: 2) } }
                            }.buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }.background(Theme.background)
                    NativeCodeEditor(text: textBinding, language: language)
                    HStack { Text(language); Spacer(); Text("\(textBinding.wrappedValue.components(separatedBy: "\n").count) lines"); Text("UTF-8") }.font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted).padding(10).background(Theme.sidebar)
                }.frame(minWidth: 340, idealWidth: 540)
                VStack(spacing: 0) {
                    HStack { Circle().fill(Theme.accent).frame(width: 5, height: 5); Text("LOCAL PREVIEW").tracking(1.4); Spacer(); Image(systemName: "lock.shield") }.font(.system(size: 9)).foregroundStyle(Theme.muted).padding(.horizontal, 18).frame(height: 41).background(Theme.panel)
                    GeometryReader { geo in
                        WebPreview(source: preview, reloadToken: reloadToken, onConsole: { text in console.append(text); if console.count > 100 { console.removeFirst(console.count - 100) }; if text.hasPrefix("[error]") { showConsole = true } }).frame(width: viewport == "Mobile" ? min(390, geo.size.width) : viewport == "Tablet" ? min(768, geo.size.width) : geo.size.width)
                            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.background)
                    }
                    if showConsole {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Text("CONSOLE"); Spacer(); Button("Clear") { console = [] }.buttonStyle(.plain) }.font(.system(size: 9)).foregroundStyle(Theme.muted)
                            ScrollView { VStack(alignment: .leading, spacing: 5) { ForEach(Array(console.enumerated()), id: \.offset) { _, line in Text(line).font(.system(size: 10, design: .monospaced)).foregroundStyle(line.hasPrefix("[error]") ? Color.red : Theme.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) } } }
                        }.padding(10).frame(height: 125).background(Theme.background)
                    }
                    Text("Preview runs your HTML and JavaScript in an isolated WebKit data store. External resources need a network connection.")
                        .font(.system(size: 9)).foregroundStyle(Theme.muted).padding(10).frame(maxWidth: .infinity).background(Theme.sidebar)
                }.frame(minWidth: 360, idealWidth: 650)
            }
        }.onAppear { preview = source }
            .task(id: source + String(live)) {
                guard live else { return }
                do { try await Task.sleep(nanoseconds: 600_000_000); preview = source } catch { }
            }
    }
}
