import SwiftUI

struct ContentView: View {
    @State private var store = WorkoutStore()
    @State private var session: WorkoutSession?

    var body: some View {
        Group {
            if let session {
                switch session.screen {
                case .setup:
                    SetupView(store: store, start: startWorkout)
                case .running:
                    WorkoutView(session: session)
                case .completed:
                    CompletionView(session: session) {
                        self.session = nil
                    }
                }
            } else {
                SetupView(store: store, start: startWorkout)
            }
        }
        .preferredColorScheme(store.appearance.colorScheme)
        .foregroundStyle(HIITTheme.ink)
    }

    private func startWorkout() {
        let newSession = WorkoutSession(configuration: store.configuration)
        session = newSession
        newSession.start()
    }
}

#Preview {
    ContentView()
}
