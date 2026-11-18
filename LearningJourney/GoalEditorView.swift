import SwiftUI

struct GoalEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var topic = ""
    @State private var period: GoalPeriod = .week
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("I want to learn")
                        .font(.caption)
                    TextField("Swift", text: $topic)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, 11)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("I want to learn it in a")
                        .font(.caption)
                    PeriodPicker(selection: $period)
                }

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Learning Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.goal != nil {
                            showingConfirmation = true
                        } else {
                            saveGoal()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.orange, in: Circle())
                    }
                    .disabled(topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("Update goal?", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("Update", role: .destructive) { saveGoal() }
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text("If you update now, your streak will start over.")
            }
            .onAppear {
                topic = viewModel.goal?.topic ?? ""
                period = viewModel.goal?.period ?? .week
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveGoal() {
        viewModel.startGoal(topic: topic, period: period)
        dismiss()
    }
}
