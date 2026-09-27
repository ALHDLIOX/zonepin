import Foundation

enum ClockFormatter {
    static let defaultTimeZoneIdentifier = "Asia/Shanghai"
    static let dateFormat = "EEE MMM d HH:mm"

    static func timeZone(for identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone(identifier: defaultTimeZoneIdentifier)!
    }

    static func string(for date: Date, timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone(for: timeZoneIdentifier)
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }

    static func utcOffset(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds < 0 ? "−" : "+"
        let absoluteMinutes = abs(seconds) / 60
        return String(format: "UTC%@%02d:%02d", sign, absoluteMinutes / 60, absoluteMinutes % 60)
    }
}
