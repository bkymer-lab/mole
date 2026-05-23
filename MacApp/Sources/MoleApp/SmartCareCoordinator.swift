import Foundation

@MainActor
public final class SmartCareCoordinator {
    private(set) var state: SmartCareFlowState = .idle
    private var activeRunID: UUID?

    public func begin() -> UUID {
        let runID = UUID()
        activeRunID = runID
        state = .preparing
        return runID
    }

    public func markScanning(runID: UUID) -> Bool {
        guard activeRunID == runID else { return false }
        state = .scanning
        return true
    }

    public func complete(runID: UUID) -> Bool {
        guard activeRunID == runID else { return false }
        state = .review
        activeRunID = nil
        return true
    }

    public func fail(runID: UUID, message: String) -> Bool {
        guard activeRunID == runID else { return false }
        state = .failure(message)
        activeRunID = nil
        return true
    }

    public func advanceFromReview() {
        switch state {
        case .review:
            state = .explain
        case .explain:
            state = .resolve
        case .resolve:
            state = .summary
        default:
            break
        }
    }

    public func reset() {
        activeRunID = nil
        state = .idle
    }
}
