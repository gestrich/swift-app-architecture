import Vapor
import GreetingFeature
import CoreService

func configure(_ app: Application) async throws {
    let useCase = GreetingUseCase()

    app.get("greet") { req async throws -> Greeting in
        guard let name = req.query[String.self, at: "name"] else {
            throw Abort(.badRequest, reason: "Missing 'name' query parameter")
        }
        do {
            let result = try await useCase.run(
                options: .init(config: GreetingConfig(recipient: name))
            )
            guard let greeting = result.completedGreeting else {
                throw Abort(.internalServerError, reason: "Use case finished without greeting")
            }
            return greeting
        } catch GreetingError.recipientEmpty {
            throw Abort(.badRequest, reason: "Recipient must not be empty")
        }
    }
}

extension Greeting: @retroactive Content {}
