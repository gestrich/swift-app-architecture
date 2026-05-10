import Foundation

public protocol UseCase: Sendable {
    associatedtype Options: Sendable = Void
    associatedtype Result: Sendable

    func run(options: Options) async throws -> Result
}

extension UseCase where Options == Void {
    public func run() async throws -> Result {
        try await run(options: ())
    }
}

public protocol StreamingUseCase: UseCase {
    associatedtype State: Sendable

    func stream(options: Options) -> AsyncThrowingStream<State, Error>
}

extension StreamingUseCase where Result == State {
    public func run(options: Options) async throws -> Result {
        var last: State?
        for try await state in stream(options: options) {
            last = state
        }
        guard let last else {
            throw UniflowError.streamFinishedWithoutValue
        }
        return last
    }
}

public enum UniflowError: Error, Sendable {
    case streamFinishedWithoutValue
}
