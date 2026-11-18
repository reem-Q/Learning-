import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var topic = ""
    @State private var period: GoalPeriod = .week

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .padding(.top, 56)

            Spacer().frame(height: 64)

            VStack(alignment: .leading, spacing: 5) {
                (
                    Text("Hello ") + Text("Learner").bold()
                )
                .font(.system(size: 27))
                Text("This app will help you learn everyday!")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text("I want to learn")
                    .font(.caption)
                TextField("Swift", text: $topic)
                    .textInputAutocapitalization(.words)
                    .padding(.vertical, 11)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
                    }

                Text("I want to learn it in a")
                    .font(.caption)
                    .padding(.top, 12)

                PeriodPicker(selection: $period)
            }
            .padding(.top, 32)

            Spacer(minLength: 30)

            Button {
                viewModel.startGoal(topic: topic.isEmpty ? "Swift" : topic, period: period)
            } label: {
                Text("Start Learning")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(AppTheme.orange, in: Capsule())
            }
            .padding(.bottom, 8)

            Text("You can edit your desire later")
                .font(.caption2)
                .foregroundStyle(AppTheme.muted)
                .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
        .background(AppTheme.background)
    }
}

struct PeriodPicker: View {
    @Binding var selection: GoalPeriod

    var body: some View {
        HStack(spacing: 10) {
            ForEach(GoalPeriod.allCases) { period in
                Button {
                    selection = period
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(selection == period ? .white : AppTheme.muted)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 10)
                        .background(selection == period ? AppTheme.orange : AppTheme.surface, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(selection == period ? 0.2 : 0.1)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
