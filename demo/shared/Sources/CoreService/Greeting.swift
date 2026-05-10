import Foundation

public struct Greeting: Sendable, Equatable, Codable {
    public let recipient: String
    public let salutation: String

    public init(recipient: String, salutation: String) {
        self.recipient = recipient
        self.salutation = salutation
    }

    public var formatted: String {
        "\(salutation), \(recipient)!"
    }
}

public struct GreetingConfig: Sendable {
    public let recipient: String
    public let now: Date

    public init(recipient: String, now: Date = Date()) {
        self.recipient = recipient
        self.now = now
    }
}
