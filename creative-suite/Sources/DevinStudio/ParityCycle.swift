import AppKit
import ApplicationServices
import CryptoKit
import DevinCore

struct ReferenceApplicationSnapshot: Codable {
    let bundleIdentifier: String
    let running: Bool
    let version: String?
    let menuHeadings: [String]
    let accessibilityError: Int32?
}
struct ParityCycleReport: Codable {
    let id: String
    let sourceFingerprint: String
    let artifactsDirectory: String
    let featureIDs: [String]
    let audit: ParityAuditResult
    let referenceApplications: [ReferenceApplicationSnapshot]
    let screenCaptureAuthorized: Bool
    let artifactHashes: [String: String]
    let note: String
    let localScope: String?
}

enum ParityCycle {
    static func fingerprint(root: URL) throws -> String {
        var files = [root.appendingPathComponent("Package.swift")]
        for name in ["Sources", "Tests", "scripts"] {
            if let enumerator = FileManager.default.enumerator(at: root.appendingPathComponent(name), includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let file as URL in enumerator where ["swift", "sh", "json"].contains(file.pathExtension) {
                    if try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true { files.append(file) }
                }
            }
        }
        var hash = SHA256()
        for file in files.sorted(by: { $0.path < $1.path }) {
            let relative = String(file.path.dropFirst(root.path.count))
            let checked = try safeFile(String(relative.dropFirst()), under: root)
            hash.update(data: Data(relative.utf8)); hash.update(data: try Data(contentsOf: checked))
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
    static func safeFile(_ name: String, under root: URL) throws -> URL {
        let base = root.resolvingSymlinksInPath().standardizedFileURL
        let file = root.appendingPathComponent(name).resolvingSymlinksInPath().standardizedFileURL
        guard !name.hasPrefix("/"), file.path.hasPrefix(base.path + "/") else { throw DocumentError.invalid("An audit artifact path escapes its allowed directory.") }
        return file
    }
    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    @MainActor static func referenceSnapshot(_ identifier: String) -> ReferenceApplicationSnapshot {
        guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first else { return ReferenceApplicationSnapshot(bundleIdentifier: identifier, running: false, version: nil, menuHeadings: [], accessibilityError: nil) }
        let version = running.bundleURL.flatMap { Bundle(url: $0)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String }
        let app = AXUIElementCreateApplication(running.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 2)
        var barValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute as CFString, &barValue)
        guard status == .success, let barValue, CFGetTypeID(barValue) == AXUIElementGetTypeID() else { return ReferenceApplicationSnapshot(bundleIdentifier: identifier, running: true, version: version, menuHeadings: [], accessibilityError: status.rawValue) }
        let bar = unsafeBitCast(barValue, to: AXUIElement.self)
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(bar, kAXChildrenAttribute as CFString, &children)
        let names = (children as? [AXUIElement] ?? []).compactMap { child -> String? in
            var title: CFTypeRef?
            guard AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &title) == .success else { return nil }
            return title as? String
        }
        return ReferenceApplicationSnapshot(bundleIdentifier: identifier, running: true, version: version, menuHeadings: names, accessibilityError: nil)
    }
    @MainActor static func run(root: URL, workspaceOnly: Bool = false) async -> Int32 {
        do {
            guard FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path) else { throw DocumentError.invalid("Run the parity cycle against the Devin Creative repository.") }
            let output = root.appendingPathComponent(".build/parity-cycles", isDirectory: true)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            let latest = output.appendingPathComponent(workspaceOnly ? "latest-workspace.json" : "latest.json")
            var previous = Set<String>()
            if FileManager.default.fileExists(atPath: latest.path) { previous = Set(try JSONDecoder().decode(ParityCycleReport.self, from: Data(contentsOf: latest)).featureIDs) }
            let id = UUID().uuidString, source = try fingerprint(root: root)
            let directory = output.appendingPathComponent(id, isDirectory: true)
            let references = [referenceSnapshot("com.adobe.Photoshop"), referenceSnapshot("com.adobe.AfterEffects")]
            let localPassed: Bool
            if workspaceOnly {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
                do { let count = try await WorkspaceBehaviorVerification.run(directory: directory); print("\(count) workspace checks passed."); localPassed = true }
                catch { print("Workspace verification failed: " + error.localizedDescription); localPassed = false }
            } else { localPassed = await Verification.run(artifactsDirectory: directory) }
            let contractsRoot = root.appendingPathComponent("Tests/ReferenceContracts", isDirectory: true)
            let contractFiles = try FileManager.default.contentsOfDirectory(at: contractsRoot, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }
            var comparisons: [ContractComparison] = [], hashes: [String: String] = [:]
            for file in contractFiles {
                let file = try safeFile(file.lastPathComponent, under: contractsRoot)
                let data = try Data(contentsOf: file)
                guard data.count <= 4_000_000 else { throw DocumentError.invalid("The reference contract is too large.") }
                hashes["contract/" + file.lastPathComponent] = digest(data)
                for contract in try JSONDecoder().decode([BehaviorContract].self, from: data) {
                    let observation = try safeFile(contract.observationFile, under: directory)
                    var observed: [String: Bool]?
                    if FileManager.default.fileExists(atPath: observation.path) {
                        let data = try Data(contentsOf: observation); hashes["observation/" + contract.observationFile] = digest(data)
                        observed = try JSONDecoder().decode([String: Bool].self, from: data)
                    }
                    var checked = false
                    if let artifact = contract.referenceArtifact {
                        let reference = try safeFile(artifact, under: contractsRoot)
                        if FileManager.default.fileExists(atPath: reference.path) {
                            let data = try Data(contentsOf: reference); hashes["reference/" + artifact] = digest(data)
                            let values = try JSONDecoder().decode([String: Bool].self, from: data)
                            checked = !values.isEmpty && values == contract.expected
                        }
                    }
                    comparisons.append(ParityAudit.compare(contract, observed: observed, referenceArtifactChecked: checked))
                }
            }
            var audit = ParityAudit.assess(features: ParityLedger.all, comparisons: comparisons, localChecksPassed: localPassed, previousFeatureIDs: previous)
            if try fingerprint(root: root) != source {
                audit = ParityAuditResult(disposition: "regression", localChecksPassed: false, comparisons: comparisons, unresolvedFeatureIDs: ParityLedger.all.map(\.id), blockers: ["Source files changed during verification. Run another cycle."])
            }
            let report = ParityCycleReport(id: id, sourceFingerprint: source, artifactsDirectory: directory.path, featureIDs: ParityLedger.all.map(\.id), audit: audit, referenceApplications: references, screenCaptureAuthorized: CGPreflightScreenCaptureAccess(), artifactHashes: hashes, note: "Documentation-derived contracts are not observed Adobe output. This cycle never edits reference fixtures or source files. The repair runner is a separate step.", localScope: workspaceOnly ? "workspace" : "full")
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)
            try data.write(to: directory.appendingPathComponent("parity-report.json"), options: .atomic)
            try data.write(to: latest, options: .atomic)
            for comparison in comparisons { print("CONTRACT \(comparison.id): \(comparison.passed ? "PASS" : "FAIL") [\(comparison.evidenceKind.rawValue)]") }
            for blocker in audit.blockers { print("BLOCKED: " + blocker) }
            print("Parity cycle: \(audit.disposition). Report: \(latest.path)")
            return audit.exitCode
        } catch { print("Parity cycle error: " + error.localizedDescription); return 1 }
    }
}
