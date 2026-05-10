import Foundation
import Testing
@testable import CoreService

@Suite("Greeting model")
struct GreetingTests {
    @Test("Formatted combines salutation and recipient with punctuation")
    func formattedJoinsParts() {
        let greeting = Greeting(recipient: "Bill", salutation: "Good morning")
        #expect(greeting.formatted == "Good morning, Bill!")
    }

    @Test("Greeting round-trips through Codable")
    func codableRoundTrip() throws {
        let greeting = Greeting(recipient: "Bill", salutation: "Good evening")
        let data = try JSONEncoder().encode(greeting)
        let decoded = try JSONDecoder().decode(Greeting.self, from: data)
        #expect(decoded == greeting)
    }
}
