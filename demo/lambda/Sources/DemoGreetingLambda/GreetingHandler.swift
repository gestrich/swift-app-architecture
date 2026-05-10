import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import GreetingFeature
import CoreService

struct GreetingHandler {
    let useCase: GreetingUseCase

    func handle(_ event: APIGatewayV2Request) async -> APIGatewayV2Response {
        let name = event.queryStringParameters["name"]
        guard let recipient = name, !recipient.isEmpty else {
            return APIGatewayV2Response(
                statusCode: .badRequest,
                body: #"{"error":"Missing 'name' query parameter"}"#
            )
        }
        do {
            let state = try await useCase.run(
                options: .init(config: GreetingConfig(recipient: recipient))
            )
            guard let greeting = state.completedGreeting else {
                return APIGatewayV2Response(
                    statusCode: .internalServerError,
                    body: #"{"error":"Use case finished without greeting"}"#
                )
            }
            return APIGatewayV2Response(
                statusCode: .ok,
                headers: ["Content-Type": "application/json"],
                body: encode(greeting)
            )
        } catch GreetingError.recipientEmpty {
            return APIGatewayV2Response(
                statusCode: .badRequest,
                body: #"{"error":"Recipient must not be empty"}"#
            )
        } catch {
            return APIGatewayV2Response(
                statusCode: .internalServerError,
                body: #"{"error":"Unexpected failure"}"#
            )
        }
    }

    private func encode(_ greeting: Greeting) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(greeting),
              let json = String(data: data, encoding: .utf8) else {
            return #"{"error":"encoding failed"}"#
        }
        return json
    }
}
