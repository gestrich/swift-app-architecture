import Foundation

public enum TimeOfDay: String, Sendable, CaseIterable, Codable {
    case morning
    case afternoon
    case evening
}

public struct TimeOfDayClient: Sendable {
    public init() {}

    public func timeOfDay(at date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }
}
