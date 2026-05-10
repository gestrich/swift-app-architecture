import AWSLambdaRuntime
import AWSLambdaEvents
import GreetingFeature

@main
struct DemoGreetingLambda {
    static func main() async throws {
        let handler = GreetingHandler(useCase: GreetingUseCase())
        let runtime = LambdaRuntime { (event: APIGatewayV2Request, context: LambdaContext) async -> APIGatewayV2Response in
            await handler.handle(event)
        }
        try await runtime.run()
    }
}
