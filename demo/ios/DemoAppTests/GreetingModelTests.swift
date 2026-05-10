import Foundation
import Testing
import GreetingFeature
@testable import DemoApp

@Suite("GreetingModel — bridges use case stream to view-facing state")
@MainActor
struct GreetingModelTests {
    @Test("Reaches .ready with a formatted greeting after generate()")
    func generateReachesReady() async throws {
        let model = GreetingModel(useCase: GreetingUseCase())
        model.recipientInput = "Bill"
        model.generate()

        try await waitForReady(model)

        let greeting = try #require(model.state.completedGreeting)
        #expect(greeting.recipient == "Bill")
        #expect(greeting.formatted.hasSuffix("Bill!"))
    }

    @Test("Rejects whitespace-only input via .error")
    func emptyRecipientGoesToError() async throws {
        let model = GreetingModel(useCase: GreetingUseCase())
        model.recipientInput = "   "
        model.generate()

        try await waitFor(model) { state in
            if case .error = state { return true }
            return false
        }

        guard case .error = model.state else {
            Issue.record("expected .error state, got \(model.state)")
            return
        }
    }

    private func waitForReady(_ model: GreetingModel) async throws {
        try await waitFor(model) { state in
            if case .ready = state { return true }
            return false
        }
    }

    private func waitFor(
        _ model: GreetingModel,
        timeout: Duration = .seconds(2),
        until predicate: (GreetingModel.ModelState) -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if predicate(model.state) { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("timed out waiting for state; last was \(model.state)")
    }
}
