import Foundation
import Testing
import Vapor
import VaporTesting
import CoreService
@testable import DemoVaporServer

@Suite("GET /greet")
struct GreetingRouteTests {
    @Test("Returns a Greeting JSON for valid name")
    func returnsGreeting() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "greet?name=Bill") { res async throws in
                #expect(res.status == .ok)
                let greeting = try res.content.decode(Greeting.self)
                #expect(greeting.recipient == "Bill")
                #expect(greeting.formatted.hasSuffix("Bill!"))
            }
        }
    }

    @Test("Missing name returns 400")
    func missingNameReturnsBadRequest() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "greet") { res async throws in
                #expect(res.status == .badRequest)
            }
        }
    }

    private func withApp(_ work: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await work(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
