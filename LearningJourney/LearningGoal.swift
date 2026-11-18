import Foundation

enum GoalPeriod: String, CaseIterable, Codable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var targetDays: Int {
        switch self {
        case .week: 5
        case .month: 20
        case .year: 240
        }
    }

    var freezeLimit: Int {
        switch self {
        case .week: 2
        case .month: 8
        case .year: 96
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}

struct LearningGoal: Codable {
    var topic: String
    var period: GoalPeriod
    var startDate: Date
}

enum ActivityStatus: String, Codable {
    case learned
    case frozen
}

struct DayRecord: Codable, Identifiable {
    var date: Date
    var status: ActivityStatus
    var loggedAt: Date

    var id: Date { date }

    init(date: Date, status: ActivityStatus, loggedAt: Date = Date()) {
        self.date = date
        self.status = status
        self.loggedAt = loggedAt
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case status
        case loggedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        status = try container.decode(ActivityStatus.self, forKey: .status)
        loggedAt = try container.decodeIfPresent(Date.self, forKey: .loggedAt) ?? date
    }
}
