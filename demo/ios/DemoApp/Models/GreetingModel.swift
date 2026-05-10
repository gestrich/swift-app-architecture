import Foundation
import Observation
import CoreService
import GreetingFeature

@MainActor @Observable
final class GreetingModel {
    var state: ModelState = .idle
    var recipientInput: String = ""

    private let useCase: GreetingUseCase

    init(useCase: GreetingUseCase) {
        self.useCase = useCase
    }

    func generate() {
        let recipient = recipientInput
        let prior = state.completedGreeting
        state = .running(.preparing, prior: prior)
        Task {
            do {
                let config = GreetingConfig(recipient: recipient)
                for try await useCaseState in useCase.stream(options: .init(config: config)) {
                    state = ModelState(from: useCaseState, prior: prior)
                }
            } catch {
                state = .error(error, prior: prior)
            }
        }
    }

    enum ModelState {
        case idle
        case running(GreetingState, prior: Greeting?)
        case ready(Greeting)
        case error(Error, prior: Greeting?)

        var completedGreeting: Greeting? {
            switch self {
            case .ready(let greeting): return greeting
            case .running(_, let prior): return prior
            case .error(_, let prior): return prior
            case .idle: return nil
            }
        }

        init(from useCaseState: GreetingState, prior: Greeting?) {
            if let greeting = useCaseState.completedGreeting {
                self = .ready(greeting)
            } else {
                self = .running(useCaseState, prior: prior)
            }
        }
    }
}
