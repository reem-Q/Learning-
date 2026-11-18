import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var goal: LearningGoal?
    @Published private(set) var records: [DayRecord] = []

    private let storageKey = "learning-journey-state"
    private let calendar = Calendar.current
    private let streakResetInterval: TimeInterval = 32 * 60 * 60

    init() {
        load()
    }

    struct StreakCounts {
        var learned = 0
        var frozen = 0

        var total: Int { learned + frozen }
    }

    func streakCounts(asOf now: Date = Date()) -> StreakCounts {
        let logs = recordsInCurrentGoal
            .filter { $0.loggedAt <= now }
            .sorted { $0.loggedAt < $1.loggedAt }
        guard let latest = logs.last,
              now.timeIntervalSince(latest.loggedAt) <= streakResetInterval else {
            return StreakCounts()
        }

        var streak = [latest]
        var nextLogTime = latest.loggedAt
        for record in logs.dropLast().reversed() {
            guard nextLogTime.timeIntervalSince(record.loggedAt) <= streakResetInterval else { break }
            streak.append(record)
            nextLogTime = record.loggedAt
        }

        return StreakCounts(
            learned: streak.filter { $0.status == .learned }.count,
            frozen: streak.filter { $0.status == .frozen }.count
        )
    }

    func freezesUsed(asOf now: Date = Date()) -> Int {
        recordsInCurrentGoal.filter { $0.status == .frozen && $0.loggedAt <= now }.count
    }

    func remainingFreezes(asOf now: Date = Date()) -> Int {
        guard let goal else { return 0 }
        return max(0, goal.period.freezeLimit - freezesUsed(asOf: now))
    }

    func goalState(asOf now: Date = Date()) -> GoalState {
        guard let goal else { return .active }
        if streakCounts(asOf: now).total >= goal.period.targetDays { return .completed }
        guard let endDate = calendar.date(byAdding: goal.period.calendarComponent, value: 1, to: goal.startDate) else {
            return .active
        }
        return now >= endDate ? .missed : .active
    }

    enum GoalState {
        case active
        case completed
        case missed
    }

    func status(for date: Date) -> ActivityStatus? {
        let day = calendar.startOfDay(for: date)
        return records.first { calendar.isDate($0.date, inSameDayAs: day) }?.status
    }

    func canLog(_ date: Date, asOf now: Date = Date()) -> Bool {
        guard let goal, goalState(asOf: now) == .active else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: goal.startDate)
            && calendar.isDate(day, inSameDayAs: now)
            && status(for: day) == nil
    }

    func startGoal(topic: String, period: GoalPeriod) {
        let cleanedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTopic.isEmpty else { return }
        goal = LearningGoal(topic: cleanedTopic, period: period, startDate: Date())
        save()
    }

    func log(_ status: ActivityStatus, for date: Date, asOf now: Date = Date()) {
        guard canLog(date, asOf: now) else { return }
        if status == .frozen && remainingFreezes(asOf: now) == 0 { return }
        records.append(DayRecord(date: calendar.startOfDay(for: date), status: status, loggedAt: now))
        save()
    }

    func records(in month: Date) -> [DayRecord] {
        records.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    private var recordsInCurrentGoal: [DayRecord] {
        guard let goal else { return [] }
        return records.filter { $0.loggedAt >= goal.startDate }
    }

    private struct PersistedState: Codable {
        var goal: LearningGoal?
        var records: [DayRecord]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let state = try JSONDecoder().decode(PersistedState.self, from: data)
            goal = state.goal
            records = state.records
        } catch {
            NSLog("Unable to load saved learning progress: %@", String(describing: error))
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(PersistedState(goal: goal, records: records))
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            NSLog("Unable to save learning progress: %@", String(describing: error))
        }
    }
}
