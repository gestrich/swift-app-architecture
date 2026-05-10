import Vapor
import GreetingFeature

@main
struct DemoVaporServer {
    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)
        defer { Task { try await app.asyncShutdown() } }
        try await configure(app)
        try await app.execute()
    }
}
