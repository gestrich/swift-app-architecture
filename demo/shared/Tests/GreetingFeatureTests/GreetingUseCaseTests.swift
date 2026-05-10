import Foundation
import Testing
import CoreService
import GreetingClientSDK
@testable import GreetingFeature

@Suite("GreetingUseCase")
struct GreetingUseCaseTests {
    @Test("Yields preparing → composing → completed for a valid recipient")
    func happyPath() async throws {
        let useCase = GreetingUseCase()
        let morning = Self.fixedDate(hour: 9)
        let config = GreetingConfig(recipient: "Bill", now: morning)

        var emitted: [GreetingState] = []
        for try await state in useCase.stream(options: .init(config: config)) {
            emitted.append(state)
        }

        #expect(emitted.count == 3)
        if case .preparing = emitted[0] {} else { Issue.record("expected .preparing first") }
        if case .composing = emitted[1] {} else { Issue.record("expected .composing second") }
        let completed = try #require(emitted.last?.completedGreeting)
        #expect(completed.formatted == "Good morning, Bill!")
    }

    @Test(
        "Salutation matches time of day",
        arguments: [
            (9, "Good morning"),
            (14, "Good afternoon"),
            (22, "Good evening"),
        ]
    )
    func salutationByHour(hour: Int, expected: String) async throws {
        let useCase = GreetingUseCase()
        let config = GreetingConfig(recipient: "Bill", now: Self.fixedDate(hour: hour))
        let result = try await useCase.run(options: .init(config: config))
        let greeting = try #require(result.completedGreeting)
        #expect(greeting.salutation == expected)
    }

    @Test("Empty recipient throws GreetingError.recipientEmpty")
    func emptyRecipientThrows() async {
        let useCase = GreetingUseCase()
        let config = GreetingConfig(recipient: "   ", now: Self.fixedDate(hour: 9))
        await #expect(throws: GreetingError.recipientEmpty) {
            _ = try await useCase.run(options: .init(config: config))
        }
    }

    private static func fixedDate(hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 10
        components.hour = hour
        components.minute = 0
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}
