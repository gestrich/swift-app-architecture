import SwiftUI
import GreetingFeature

@main
struct DemoApp: App {
    @State private var greetingModel = GreetingModel(useCase: GreetingUseCase())

    var body: some Scene {
        WindowGroup {
            GreetingView(model: greetingModel)
        }
    }
}
