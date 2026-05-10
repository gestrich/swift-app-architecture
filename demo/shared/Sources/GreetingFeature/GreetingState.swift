import CoreService

public enum GreetingState: Sendable {
    case preparing
    case composing
    case completed(Greeting)

    public var completedGreeting: Greeting? {
        if case .completed(let greeting) = self { return greeting }
        return nil
    }
}
