import Foundation
import Testing
import AWSLambdaEvents
import CoreService
import GreetingFeature
@testable import DemoGreetingLambda

@Suite("GreetingHandler")
struct GreetingHandlerTests {
    @Test("Returns 200 with greeting JSON when name is supplied")
    func returnsGreeting() async throws {
        let handler = GreetingHandler(useCase: GreetingUseCase())
        let event = try makeEvent(query: ["name": "Bill"])

        let response = await handler.handle(event)

        #expect(response.statusCode == .ok)
        let body = try #require(response.body)
        let data = try #require(body.data(using: .utf8))
        let greeting = try JSONDecoder().decode(Greeting.self, from: data)
        #expect(greeting.recipient == "Bill")
        #expect(greeting.formatted.hasSuffix("Bill!"))
    }

    @Test("Returns 400 when name is missing")
    func missingNameReturnsBadRequest() async throws {
        let handler = GreetingHandler(useCase: GreetingUseCase())
        let response = await handler.handle(try makeEvent(query: [:]))
        #expect(response.statusCode == .badRequest)
    }

    private func makeEvent(query: [String: String]) throws -> APIGatewayV2Request {
        let queryJSON: String
        if query.isEmpty {
            queryJSON = "{}"
        } else {
            let pairs = query.map { #""\#($0)":"\#($1)""# }.joined(separator: ",")
            queryJSON = "{\(pairs)}"
        }
        let json = """
        {
            "version": "2.0",
            "routeKey": "GET /greet",
            "rawPath": "/greet",
            "rawQueryString": "",
            "headers": {},
            "queryStringParameters": \(queryJSON),
            "requestContext": {
                "accountId": "0",
                "apiId": "api",
                "domainName": "example.com",
                "domainPrefix": "ex",
                "stage": "test",
                "requestId": "req",
                "http": {
                    "method": "GET",
                    "path": "/greet",
                    "protocol": "HTTP/1.1",
                    "sourceIp": "127.0.0.1",
                    "userAgent": "test"
                },
                "time": "10/May/2026:00:00:00 +0000",
                "timeEpoch": 0
            },
            "isBase64Encoded": false
        }
        """
        let data = Data(json.utf8)
        return try JSONDecoder().decode(APIGatewayV2Request.self, from: data)
    }
}
