import SwiftUI
import CoreService
import GreetingFeature

struct GreetingView: View {
    @State private var model: GreetingModel

    init(model: GreetingModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Your name", text: $model.recipientInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                Button("Generate Greeting") {
                    model.generate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.recipientInput.trimmingCharacters(in: .whitespaces).isEmpty)

                statusView
                Spacer()
            }
            .padding()
            .navigationTitle("Demo Greeter")
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch model.state {
        case .idle:
            Text("Enter a name to receive a time-aware greeting.")
                .foregroundStyle(.secondary)
        case .running(let state, _):
            HStack {
                ProgressView()
                Text(label(for: state))
            }
        case .ready(let greeting):
            Text(greeting.formatted)
                .font(.title2)
                .bold()
        case .error(let error, _):
            Text("Couldn't compose a greeting: \(error.localizedDescription)")
                .foregroundStyle(.red)
        }
    }

    private func label(for state: GreetingState) -> String {
        switch state {
        case .preparing: return "Preparing…"
        case .composing: return "Composing…"
        case .completed: return "Done"
        }
    }
}

#Preview {
    GreetingView(model: GreetingModel(useCase: GreetingUseCase()))
}
