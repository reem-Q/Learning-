import SwiftUI

@main
struct LearningJourneyApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Group {
            if viewModel.goal == nil {
                OnboardingView()
            } else {
                ActivityView()
            }
        }
        .tint(AppTheme.orange)
    }
}

enum AppTheme {
    static let background = Color.black
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let orange = Color(red: 1.0, green: 0.54, blue: 0.12)
    static let cyan = Color(red: 0.07, green: 0.76, blue: 0.91)
    static let muted = Color.gray
}
