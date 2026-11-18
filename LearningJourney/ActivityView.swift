import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showingCalendar = false
    @State private var showingGoalEditor = false
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    weekStrip
                    stats

                    if viewModel.goalState(asOf: currentTime) == .active {
                        dailyActions
                    } else {
                        goalResult
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingCalendar) {
            CalendarView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView()
                .environmentObject(viewModel)
        }
        .onChange(of: viewModel.goal?.startDate) { _, startDate in
            if let startDate { selectedDate = calendar.startOfDay(for: startDate) }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                refreshCurrentTime()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshCurrentTime() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Activity")
                        .font(.system(size: 28, weight: .bold))
                    if let goal = viewModel.goal {
                        Text(goal.topic)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                Spacer()

                Button { showingCalendar = true } label: {
                    CircleIcon(systemName: "calendar")
                }
                .accessibilityLabel("Open activities calendar")

                Button { showingGoalEditor = true } label: {
                    CircleIcon(systemName: "timer")
                }
                .accessibilityLabel("Edit learning goal")
            }
            Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var weekStrip: some View {
        let days = weekDates(containing: selectedDate)
        return VStack(spacing: 8) {
            HStack {
                Button {
                    shiftSelectedDate(by: -7)
                } label: {
                    Image(systemName: "chevron.left").font(.caption.weight(.bold))
                }
                .disabled(days.first.map { calendar.startOfDay(for: $0) <= calendar.startOfDay(for: viewModel.goal?.startDate ?? Date()) } ?? true)

                Spacer()
                Text("THIS WEEK")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.muted)
                Spacer()

                Button {
                    shiftSelectedDate(by: 7)
                } label: {
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .disabled(calendar.startOfDay(for: selectedDate) >= calendar.startOfDay(for: currentTime))
            }
            .foregroundStyle(AppTheme.cyan)

            HStack(spacing: 0) {
                ForEach(days, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 7) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                            dayBadge(date)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(date > calendar.startOfDay(for: currentTime))
                }
            }
        }
    }

    @ViewBuilder
    private func dayBadge(_ date: Date) -> some View {
        let status = viewModel.status(for: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let color: Color = switch status {
        case .learned: AppTheme.orange
        case .frozen: AppTheme.cyan
        case nil: AppTheme.surface
        }
        Text(date.formatted(.dateTime.day()))
            .font(.subheadline.weight(isSelected ? .bold : .medium))
            .foregroundStyle(status == nil ? .white : .black)
            .frame(width: 38, height: 38)
            .background(status == nil ? AppTheme.surface : color, in: Circle())
            .overlay(Circle().stroke(isSelected ? .white : .clear, lineWidth: 1.5))
    }

    private var stats: some View {
        let counts = viewModel.streakCounts(asOf: currentTime)
        return HStack(spacing: 12) {
            StatCard(symbol: "flame.fill", symbolColor: AppTheme.orange, value: counts.learned, title: "Learned")
            StatCard(symbol: "snowflake", symbolColor: AppTheme.cyan, value: counts.frozen, title: "Freezed")
        }
    }

    private var dailyActions: some View {
        let canLog = viewModel.canLog(selectedDate, asOf: currentTime)
        let remainingFreezes = viewModel.remainingFreezes(asOf: currentTime)
        let freezeLimit = viewModel.goal?.period.freezeLimit ?? 0
        return VStack(spacing: 20) {
            Button {
                viewModel.log(.learned, for: selectedDate, asOf: currentTime)
            } label: {
                Text(viewModel.status(for: selectedDate) == .learned ? "Logged as Learned" : "Log as Learned")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 214, height: 214)
                    .background(viewModel.status(for: selectedDate) == nil ? AppTheme.orange : AppTheme.surface, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canLog)

            VStack(spacing: 8) {
                Button {
                    viewModel.log(.frozen, for: selectedDate, asOf: currentTime)
                } label: {
                    Text(viewModel.status(for: selectedDate) == .frozen ? "Freezed for a day" : "Freeze for a day")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canLog && remainingFreezes > 0 ? AppTheme.cyan : AppTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canLog || remainingFreezes == 0)

                Text("Freezing a day protects your streak")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                Text("\(viewModel.freezesUsed(asOf: currentTime)) out of \(freezeLimit) freezes used")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(.top, 10)
    }

    private var goalResult: some View {
        VStack(spacing: 14) {
            Image(systemName: viewModel.goalState(asOf: currentTime) == .completed ? "hands.clap.fill" : "xmark")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.orange)
                .frame(height: 100)

            Text(viewModel.goalState(asOf: currentTime) == .completed ? "Well done!" : "You didn't reach your goal this time.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(viewModel.goalState(asOf: currentTime) == .completed ? "Ready for your next goal?" : "Want to set another goal?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

            Button { showingGoalEditor = true } label: {
                Label("Set a goal", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.orange, in: Capsule())
            }
            .padding(.top, 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }

    private func weekDates(containing date: Date) -> [Date] {
        let weekday = calendar.component(.weekday, from: date)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: calendar.startOfDay(for: date)) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func shiftSelectedDate(by days: Int) {
        if let date = calendar.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = min(calendar.startOfDay(for: date), calendar.startOfDay(for: currentTime))
        }
    }

    private func refreshCurrentTime() {
        let previousToday = calendar.startOfDay(for: currentTime)
        currentTime = Date()
        if calendar.isDate(selectedDate, inSameDayAs: previousToday) {
            selectedDate = calendar.startOfDay(for: currentTime)
        }
    }
}

private struct CircleIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(AppTheme.surface, in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.15)))
    }
}

private struct StatCard: View {
    let symbol: String
    let symbolColor: Color
    let value: Int
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(symbolColor)
            Text("\(value) \(value == 1 ? "day" : "days")")
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15)))
    }
}
