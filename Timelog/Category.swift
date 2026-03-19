import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case work     = "work"
    case health   = "health"
    case personal = "personal"
    case social   = "social"
    case rest     = "rest"
    case other    = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .work:     return "Work"
        case .health:   return "Health"
        case .personal: return "Personal"
        case .social:   return "Social"
        case .rest:     return "Rest"
        case .other:    return "Other"
        }
    }

    var color: Color {
        switch self {
        case .work:     return Color(hex: "4F8EF7")
        case .health:   return Color(hex: "2ECC71")
        case .personal: return Color(hex: "F7C948")
        case .social:   return Color(hex: "E67E5A")
        case .rest:     return Color(hex: "A78BFA")
        case .other:    return Color(hex: "94A3B8")
        }
    }

    var icon: String {
        switch self {
        case .work:     return "briefcase.fill"
        case .health:   return "heart.fill"
        case .personal: return "person.fill"
        case .social:   return "bubble.left.and.bubble.right.fill"
        case .rest:     return "moon.fill"
        case .other:    return "ellipsis.circle.fill"
        }
    }

    static func from(_ string: String) -> Category {
        return Category(rawValue: string) ?? .other
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
