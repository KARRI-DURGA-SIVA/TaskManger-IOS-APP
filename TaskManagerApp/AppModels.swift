import SwiftUI
import UIKit
import UserNotifications

enum AppTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case stats = "Stats"
    case settings = "Settings"
}

enum PriorityLevel: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var priority: PriorityLevel
    var category: String
    var reminderEnabled: Bool
    var isComplete = false
    var createdAt = Date()

    var subtitle: String {
        "\(Self.timeFormatter.string(from: dueDate)) · \(priority.rawValue) · \(category)"
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

struct CategorySummary: Identifiable {
    var id: String { name }
    let name: String
    let count: String
    let color: Color
    let progress: Double

    var iconName: String {
        switch name {
        case "Work":
            "briefcase.fill"
        case "Personal":
            "person.fill"
        case "Health":
            "heart.fill"
        case "Learning":
            "book.fill"
        case "Finance":
            "creditcard.fill"
        default:
            "tag.fill"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum StatsRange: String, CaseIterable {
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"

    var title: String {
        switch self {
        case .week:
            "Weekly Progress"
        case .month:
            "Monthly Progress"
        case .year:
            "Yearly Progress"
        }
    }

    var subtitle: String {
        switch self {
        case .week:
            "Completed tasks over the last 7 days"
        case .month:
            "Completed tasks over the last 30 days"
        case .year:
            "Completed tasks over the last 12 months"
        }
    }
}

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    let categories = ["Work", "Personal", "Health", "Learning", "Finance"]
    private let storageKey = "task-manager.tasks"
    private let syncClient = NeonTaskSyncClient()

    init() {
        load()
    }

    var activeTasks: [TaskItem] {
        tasks.filter { !$0.isComplete }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isComplete)
    }

    var completionProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }

    var upcomingTasks: [TaskItem] {
        activeTasks.sorted { $0.dueDate < $1.dueDate }
    }

    func addTask(title: String, description: String, dueDate: Date, priority: PriorityLevel, category: String, reminderEnabled: Bool) {
        let task = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            priority: priority,
            category: category,
            reminderEnabled: reminderEnabled
        )
        tasks.insert(task, at: 0)
        save()

        Task {
            await syncClient.upsert(task: task)
        }
    }

    func toggleComplete(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isComplete.toggle()
        save()

        let updatedTask = tasks[index]
        Task {
            await syncClient.upsert(task: updatedTask)
        }
    }

    func tasks(in category: String) -> [TaskItem] {
        tasks.filter { $0.category == category }.sorted { $0.dueDate < $1.dueDate }
    }

    func categorySummaries() -> [CategorySummary] {
        categories.enumerated().map { index, category in
            let categoryTasks = tasks(in: category)
            let completedCount = categoryTasks.filter(\.isComplete).count
            let progress = categoryTasks.isEmpty ? 0 : Double(completedCount) / Double(categoryTasks.count)

            return CategorySummary(
                name: category,
                count: "\(categoryTasks.count) \(categoryTasks.count == 1 ? "Task" : "Tasks")",
                color: categoryColor(at: index),
                progress: progress
            )
        }
    }

    private func categoryColor(at index: Int) -> Color {
        let colors = [
            AppTheme.softBlue,
            AppTheme.softGreen,
            Color(red: 0.98, green: 0.91, blue: 0.72),
            Color(red: 0.90, green: 0.88, blue: 0.98),
            Color(red: 0.98, green: 0.88, blue: 0.91)
        ]
        return colors[index % colors.count]
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decodedTasks = try? JSONDecoder().decode([TaskItem].self, from: data)
        else {
            tasks = []
            return
        }
        tasks = decodedTasks
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: notificationsKey)
            if notificationsEnabled {
                requestNotificationPermission()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["task-manager.daily-reminder"]
                )
            }
        }
    }
    @Published var focusMode: Bool {
        didSet { UserDefaults.standard.set(focusMode, forKey: focusModeKey) }
    }
    @Published var iCloudSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(iCloudSyncEnabled, forKey: iCloudSyncKey) }
    }
    @Published var defaultCategory: String {
        didSet { UserDefaults.standard.set(defaultCategory, forKey: defaultCategoryKey) }
    }
    @Published var dailyReminder: Date {
        didSet {
            UserDefaults.standard.set(dailyReminder, forKey: dailyReminderKey)
            if notificationsEnabled {
                scheduleDailyReminder()
            }
        }
    }
    @Published var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: appearanceKey) }
    }

    private let notificationsKey = "task-manager.notifications-enabled"
    private let focusModeKey = "task-manager.focus-mode"
    private let iCloudSyncKey = "task-manager.icloud-sync"
    private let defaultCategoryKey = "task-manager.default-category"
    private let dailyReminderKey = "task-manager.daily-reminder"
    private let appearanceKey = "task-manager.appearance"

    init() {
        notificationsEnabled = UserDefaults.standard.object(forKey: notificationsKey) as? Bool ?? false
        focusMode = UserDefaults.standard.object(forKey: focusModeKey) as? Bool ?? false
        iCloudSyncEnabled = UserDefaults.standard.object(forKey: iCloudSyncKey) as? Bool ?? false
        defaultCategory = UserDefaults.standard.string(forKey: defaultCategoryKey) ?? "Work"
        dailyReminder = UserDefaults.standard.object(forKey: dailyReminderKey) as? Date ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date.now) ?? Date.now
        let rawAppearance = UserDefaults.standard.string(forKey: appearanceKey) ?? AppearanceMode.system.rawValue
        appearance = AppearanceMode(rawValue: rawAppearance) ?? .system
    }

    var iCloudStatus: String {
        FileManager.default.ubiquityIdentityToken == nil ? "Not signed in" : "Signed in"
    }

    func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    scheduleDailyReminder()
                } else {
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                }
            }
        }
    }

    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["task-manager.daily-reminder"])

        var components = Calendar.current.dateComponents([.hour, .minute], from: dailyReminder)
        components.second = 0

        let content = UNMutableNotificationContent()
        content.title = "Plan your day"
        content.body = "Open your task list and pick the next thing to finish."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "task-manager.daily-reminder", content: content, trigger: trigger)
        center.add(request)
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var userName: String
    @Published private(set) var email: String

    private let nameKey = "task-manager.user-name"
    private let emailKey = "task-manager.user-email"
    private let syncClient = NeonTaskSyncClient()

    init() {
        let storedName = UserDefaults.standard.string(forKey: nameKey) ?? ""
        let storedEmail = UserDefaults.standard.string(forKey: emailKey) ?? ""
        userName = storedName
        email = storedEmail
        isAuthenticated = !storedName.isEmpty
    }

    func signIn(name: String, email: String, password: String, mode: AuthMode) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = cleanName.isEmpty ? "Task Manager User" : cleanName
        self.email = cleanEmail
        isAuthenticated = true
        UserDefaults.standard.set(userName, forKey: nameKey)
        UserDefaults.standard.set(cleanEmail, forKey: emailKey)

        let account = AuthAccount(name: userName, email: cleanEmail, password: password, mode: mode.rawValue)
        Task {
            await syncClient.syncAuth(account: account)
        }
    }

    func signOut() {
        userName = ""
        email = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }
}

enum AuthMode: String, Codable {
    case signIn
    case signUp
}

struct AuthAccount: Codable {
    var name: String
    var email: String
    var password: String
    var mode: String
    var signedAt = Date()
}

struct NeonTaskSyncClient {
    private var endpoint: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "NEON_SYNC_URL") as? String,
            !value.isEmpty
        else { return nil }
        return URL(string: value)
    }

    func upsert(task: TaskItem) async {
        await send(kind: "task.upsert", payload: task)
    }

    func syncAuth(account: AuthAccount) async {
        await send(kind: "auth.account", payload: account)
    }

    private func send<T: Encodable>(kind: String, payload: T) async {
        guard let endpoint else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let body = SyncEnvelope(kind: kind, payload: payload)
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                print("Neon sync failed: server returned an unsuccessful response")
                return
            }
        } catch {
            print("Neon sync failed: \(error.localizedDescription)")
        }
    }

    private struct SyncEnvelope<T: Encodable>: Encodable {
        var kind: String
        var payload: T
    }
}

enum AppTheme {
    static let blue = Color(red: 0.02, green: 0.47, blue: 0.98)
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
            : UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
    })
    static let card = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1)
            : UIColor(red: 0.985, green: 0.985, blue: 0.995, alpha: 1)
    })
    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1)
            : UIColor.white
    })
    static let text = Color(UIColor.label)
    static let inverseText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
    })
    static let mutedText = Color(UIColor.secondaryLabel)
    static let softBlue = Color(red: 0.86, green: 0.92, blue: 1.0)
    static let softGreen = Color(red: 0.88, green: 0.96, blue: 0.91)
    static let success = Color(red: 0.12, green: 0.78, blue: 0.36)
    static let rail = Color(UIColor.separator).opacity(0.65)
}
