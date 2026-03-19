import Foundation

extension Date {
    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    var displayDate: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    static func from(dayString: String, timeString: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: "\(dayString) \(timeString)")
    }

    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

extension Int {
    var durationString: String {
        if self < 60 { return "\(self)m" }
        let h = self / 60
        let m = self % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

func minutesBetween(_ start: Date, _ end: Date) -> Int {
    max(0, Int(end.timeIntervalSince(start) / 60))
}
