import Foundation

@main
struct ClockFormatterTests {
    static func main() {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]

        func check(_ instant: String, _ zone: String, _ expected: String) {
            guard let date = parser.date(from: instant) else {
                fatalError("Invalid test instant: \(instant)")
            }
            let actual = ClockFormatter.string(for: date, timeZoneIdentifier: zone)
            precondition(actual == expected, "\(zone) at \(instant): expected \(expected), got \(actual)")
        }

        check("2026-09-27T09:31:00Z", "America/Los_Angeles", "Sun Sep 27 02:31")
        check("2026-09-27T09:31:00Z", "Asia/Shanghai", "Sun Sep 27 17:31")
        check("2026-09-27T16:30:00Z", "Asia/Shanghai", "Mon Sep 28 00:30")
        check("2026-11-01T08:59:00Z", "America/Los_Angeles", "Sun Nov 1 01:59")
        check("2026-11-01T09:01:00Z", "America/Los_Angeles", "Sun Nov 1 01:01")
        check("2026-09-27T09:31:00Z", "Invalid/TimeZone", "Sun Sep 27 17:31")

        print("ClockFormatter tests passed")
    }
}
