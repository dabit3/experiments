import XCTest
@testable import DevinCore

final class ParityAuditTests: XCTestCase {
    func contract(kind: ReferenceEvidenceKind = .documentedBehavior, whole: Bool = false) -> BehaviorContract {
        BehaviorContract(id: "tabs", featureIDs: ["pixel.tabs"], referenceVersion: "27.10.0", references: ["https://helpx.adobe.com/ca/photoshop/desktop.html"], evidenceKind: kind, coversWholeFeature: whole, observationFile: "observed.json", expected: ["sameWindow": true], referenceArtifact: kind == .observedReference ? "reference.json" : nil)
    }
    func feature(status: ParityStatus = .partial, evidence: [String] = []) -> ParityFeature {
        ParityFeature(id: "pixel.tabs", tool: .pixel, category: "Workspace", name: "Tabs", status: status, reference: "https://helpx.adobe.com/ca/photoshop/desktop.html", implementation: [], acceptance: [], limitation: "", comparisonEvidence: evidence)
    }
    func testMissingObservationFailsTheContract() {
        let result = ParityAudit.compare(contract(), observed: nil)
        XCTAssertFalse(result.passed)
        XCTAssertEqual(result.failedAssertions, ["sameWindow"])
    }
    func testAFalseObservationCannotPass() {
        XCTAssertFalse(ParityAudit.compare(contract(), observed: ["sameWindow": false]).passed)
    }
    func testDocumentationConformanceDoesNotCertifyParity() {
        let comparison = ParityAudit.compare(contract(whole: true), observed: ["sameWindow": true])
        XCTAssertTrue(comparison.passed)
        XCTAssertFalse(comparison.completeReferenceEvidence)
        let report = ParityAudit.assess(features: [feature()], comparisons: [comparison], localChecksPassed: true)
        XCTAssertFalse(report.converged)
        XCTAssertEqual(report.exitCode, 2)
    }
    func testAClaimWithoutReferenceArtifactFails() {
        let comparison = ParityAudit.compare(contract(kind: .observedReference, whole: true), observed: ["sameWindow": true])
        XCTAssertFalse(comparison.passed)
    }
    func testVerifiedLabelWithoutEvidenceDoesNotPassTheGate() {
        let comparison = ParityAudit.compare(contract(), observed: ["sameWindow": true])
        let report = ParityAudit.assess(features: [feature(status: .verified)], comparisons: [comparison], localChecksPassed: true, declaredScopeApproved: true)
        XCTAssertFalse(report.converged)
    }
    func testOnlyCompleteComparedEvidenceCanVerifyDeclaredScope() {
        let comparison = ParityAudit.compare(contract(kind: .observedReference, whole: true), observed: ["sameWindow": true], referenceArtifactChecked: true)
        let report = ParityAudit.assess(features: [feature(status: .verified, evidence: ["reference.json"])], comparisons: [comparison], localChecksPassed: true, declaredScopeApproved: true)
        XCTAssertTrue(report.converged)
        XCTAssertEqual(report.exitCode, 0)
    }
    func testRemovingFeaturesCannotProduceConvergence() {
        let report = ParityAudit.assess(features: [], comparisons: [], localChecksPassed: true, declaredScopeApproved: true, previousFeatureIDs: ["pixel.tabs"])
        XCTAssertFalse(report.converged)
        XCTAssertTrue(report.blockers.contains { $0.contains("disappeared") })
    }
    func testLocalFailuresTakePriorityOverSuccessfulComparisons() {
        let comparison = ParityAudit.compare(contract(), observed: ["sameWindow": true])
        let report = ParityAudit.assess(features: [feature()], comparisons: [comparison], localChecksPassed: false)
        XCTAssertEqual(report.exitCode, 1)
    }
    func testDuplicateContractsBlockConvergence() {
        let comparison = ParityAudit.compare(contract(kind: .observedReference, whole: true), observed: ["sameWindow": true], referenceArtifactChecked: true)
        let report = ParityAudit.assess(features: [feature(status: .verified, evidence: ["reference.json"])], comparisons: [comparison, comparison], localChecksPassed: true, declaredScopeApproved: true)
        XCTAssertFalse(report.converged)
    }
}
