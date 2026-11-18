import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(monthsToShow, id: \.self) { month in
                        monthView(month)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var monthsToShow: [Date] {
        let start = viewModel.goal?.startDate ?? Date()
        let current = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let first = calendar.dateInterval(of: .month, for: start)?.start ?? start
        var months: [Date] = []
        var month = first
        while month <= current {
            months.append(month)
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return months.reversed()
    }

    private func monthView(_ month: Date) -> some View {
        let days = daysForMonth(month)
        return VStack(alignment: .leading, spacing: 12) {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        calendarDay(date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            if month != monthsToShow.last {
                Divider().overlay(Color.white.opacity(0.12))
            }
        }
    }

    @ViewBuilder
    private func calendarDay(_ date: Date) -> some View {
        let status = viewModel.status(for: date)
        let foreground: Color = switch status {
        case .learned: AppTheme.orange
        case .frozen: AppTheme.cyan
        case nil: .white
        }

        Text(date.formatted(.dateTime.day()))
            .font(.subheadline)
            .foregroundStyle(foreground)
            .frame(width: 34, height: 34)
            .background {
                if status != nil {
                    Circle().fill(foreground.opacity(0.16))
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(accessibilityLabel(for: date, status: status))
    }

    private func daysForMonth(_ month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDate = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDate) - 1
        let leadingBlanks = Array<Date?>(repeating: nil, count: weekday)
        let dates = range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDate)
        }
        return leadingBlanks + dates.map(Optional.some)
    }

    private func accessibilityLabel(for date: Date, status: ActivityStatus?) -> String {
        let day = date.formatted(date: .complete, time: .omitted)
        return switch status {
        case .learned: "\(day), learned"
        case .frozen: "\(day), frozen"
        case nil: day
        }
    }
}
