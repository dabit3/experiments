import Foundation

public enum ReferenceEvidenceKind: String, Codable, Sendable {
    case documentedBehavior, observedReference
}

public struct BehaviorContract: Codable, Sendable {
    public let id: String
    public let featureIDs: [String]
    public let referenceVersion: String
    public let references: [String]
    public let evidenceKind: ReferenceEvidenceKind
    public let coversWholeFeature: Bool
    public let observationFile: String
    public let expected: [String: Bool]
    public let referenceArtifact: String?
    public init(id: String, featureIDs: [String], referenceVersion: String, references: [String], evidenceKind: ReferenceEvidenceKind = .documentedBehavior, coversWholeFeature: Bool = false, observationFile: String, expected: [String: Bool], referenceArtifact: String? = nil) {
        self.id = id; self.featureIDs = featureIDs; self.referenceVersion = referenceVersion; self.references = references
        self.evidenceKind = evidenceKind; self.coversWholeFeature = coversWholeFeature; self.observationFile = observationFile; self.expected = expected; self.referenceArtifact = referenceArtifact
    }
}

public struct ContractComparison: Codable, Sendable {
    public let id: String
    public let featureIDs: [String]
    public let evidenceKind: ReferenceEvidenceKind
    public let referenceVersion: String
    public let failedAssertions: [String]
    public let evidenceErrors: [String]
    public let completeReferenceEvidence: Bool
    public var passed: Bool { failedAssertions.isEmpty && evidenceErrors.isEmpty }
}

public struct ParityAuditResult: Codable, Sendable {
    public let disposition: String
    public let localChecksPassed: Bool
    public let comparisons: [ContractComparison]
    public let unresolvedFeatureIDs: [String]
    public let blockers: [String]
    public init(disposition: String, localChecksPassed: Bool, comparisons: [ContractComparison], unresolvedFeatureIDs: [String], blockers: [String]) {
        self.disposition = disposition; self.localChecksPassed = localChecksPassed; self.comparisons = comparisons; self.unresolvedFeatureIDs = unresolvedFeatureIDs; self.blockers = blockers
    }
    public var converged: Bool { disposition == "verified-declared-scope" }
    public var exitCode: Int32 { disposition == "regression" ? 1 : converged ? 0 : 2 }
}

public enum ParityAudit {
    public static func compare(_ contract: BehaviorContract, observed: [String: Bool]?, referenceArtifactChecked: Bool = false) -> ContractComparison {
        var errors: [String] = []
        if contract.expected.isEmpty { errors.append("The contract has no assertions.") }
        if contract.featureIDs.isEmpty { errors.append("The contract has no feature mapping.") }
        if contract.referenceVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("The reference version is missing.") }
        if contract.references.isEmpty || contract.references.contains(where: { URL(string: $0)?.scheme != "https" }) { errors.append("The reference source is missing or invalid.") }
        if observed == nil { errors.append("The implementation observation is missing.") }
        if contract.evidenceKind == .observedReference && !referenceArtifactChecked { errors.append("The reference artifact is missing or was not checked.") }
        let failed = contract.expected.keys.sorted().filter { observed?[$0] != contract.expected[$0] }
        let complete = contract.evidenceKind == .observedReference && contract.coversWholeFeature && referenceArtifactChecked && errors.isEmpty && failed.isEmpty
        return ContractComparison(id: contract.id, featureIDs: contract.featureIDs, evidenceKind: contract.evidenceKind, referenceVersion: contract.referenceVersion, failedAssertions: failed, evidenceErrors: errors, completeReferenceEvidence: complete)
    }
    public static func assess(features: [ParityFeature], comparisons: [ContractComparison], localChecksPassed: Bool, declaredScopeApproved: Bool = false, previousFeatureIDs: Set<String> = []) -> ParityAuditResult {
        var blockers: [String] = []
        let featureIDs = Set(features.map(\.id))
        if features.isEmpty { blockers.append("The feature inventory is empty.") }
        if featureIDs.count != features.count { blockers.append("Feature IDs are duplicated.") }
        if Set(comparisons.map(\.id)).count != comparisons.count { blockers.append("Contract IDs are duplicated.") }
        let removed = previousFeatureIDs.subtracting(featureIDs)
        if !removed.isEmpty { blockers.append("Previously audited features disappeared: " + removed.sorted().joined(separator: ", ")) }
        let unknown = Set(comparisons.flatMap(\.featureIDs)).subtracting(featureIDs)
        if !unknown.isEmpty { blockers.append("Contracts reference unknown features: " + unknown.sorted().joined(separator: ", ")) }
        if !declaredScopeApproved { blockers.append("The complete, version-pinned reference scope is not approved.") }
        let supported = Set(comparisons.filter { $0.passed && $0.completeReferenceEvidence }.flatMap(\.featureIDs))
        let unresolved = features.filter { $0.status != .verified || $0.comparisonEvidence.isEmpty || !supported.contains($0.id) }.map(\.id).sorted()
        if !unresolved.isEmpty { blockers.append("\(unresolved.count) features still need implementation or complete reference evidence.") }
        if comparisons.isEmpty { blockers.append("No reference contracts were compared.") }
        let regression = !localChecksPassed || comparisons.contains { !$0.passed }
        let done = !regression && blockers.isEmpty && !features.isEmpty
        return ParityAuditResult(disposition: regression ? "regression" : done ? "verified-declared-scope" : "blocked", localChecksPassed: localChecksPassed, comparisons: comparisons, unresolvedFeatureIDs: unresolved, blockers: blockers)
    }
}
