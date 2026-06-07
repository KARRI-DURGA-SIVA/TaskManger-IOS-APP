import SwiftUI

enum AppTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case stats = "Stats"
    case settings = "Settings"
}

enum PriorityLevel: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct TaskItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let isComplete: Bool
}

struct CategorySummary: Identifiable {
    let id = UUID()
    let name: String
    let count: String
    let color: Color
    let progress: Double
}

enum AppTheme {
    static let blue = Color(red: 0.02, green: 0.47, blue: 0.98)
    static let background = Color(red: 0.94, green: 0.95, blue: 0.97)
    static let card = Color(red: 0.985, green: 0.985, blue: 0.995)
    static let mutedText = Color.black.opacity(0.62)
    static let softBlue = Color(red: 0.86, green: 0.92, blue: 1.0)
    static let softGreen = Color(red: 0.88, green: 0.96, blue: 0.91)
    static let success = Color(red: 0.12, green: 0.78, blue: 0.36)
    static let rail = Color.black.opacity(0.10)
}
