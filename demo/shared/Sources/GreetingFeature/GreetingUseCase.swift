import Foundation
import Uniflow
import CoreService
import GreetingClientSDK

public struct GreetingUseCase: StreamingUseCase {
    public typealias State = GreetingState
    public typealias Result = State

    public struct Options: Sendable {
        public let config: GreetingConfig

        public init(config: GreetingConfig) {
            self.config = config
        }
    }

    private let timeOfDayClient: TimeOfDayClient

    public init(timeOfDayClient: TimeOfDayClient = TimeOfDayClient()) {
        self.timeOfDayClient = timeOfDayClient
    }

    public func stream(options: Options) -> AsyncThrowingStream<GreetingState, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(.preparing)
                    try Self.validate(recipient: options.config.recipient)

                    continuation.yield(.composing)
                    let timeOfDay = timeOfDayClient.timeOfDay(at: options.config.now)
                    let salutation = Self.salutation(for: timeOfDay)
                    let greeting = Greeting(
                        recipient: options.config.recipient,
                        salutation: salutation
                    )
                    continuation.yield(.completed(greeting))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func validate(recipient: String) throws {
        let trimmed = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GreetingError.recipientEmpty
        }
    }

    static func salutation(for timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening: return "Good evening"
        }
    }
}

public enum GreetingError: Error, Sendable, Equatable {
    case recipientEmpty
}
