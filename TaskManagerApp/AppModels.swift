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

enum PlannerEntryType: String, CaseIterable, Codable {
    case activity = "Activity"
    case event = "Event"
    case note = "Note"

    var iconName: String {
        switch self { case .activity: "checkmark.circle"; case .event: "calendar"; case .note: "note.text" }
    }
}

struct PlannerEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var details: String
    var entryType: PlannerEntryType
    var scheduledAt: Date
    var isComplete = false
    var createdAt = Date()
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
    private let syncClient = SpringBootAPIClient()

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
        updateReminder(for: task)

        Task {
            await syncClient.upsert(task: task)
        }
    }

    func toggleComplete(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isComplete.toggle()
        save()

        let updatedTask = tasks[index]
        updateReminder(for: updatedTask)
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

    private func updateReminder(for task: TaskItem) {
        let center = UNUserNotificationCenter.current()
        let identifier = "task-manager.task.\(task.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard task.reminderEnabled, !task.isComplete, task.dueDate > Date.now else { return }
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.description.isEmpty ? "This task is due now." : task.description
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(task.dueDate.timeIntervalSinceNow, 1),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}

@MainActor
final class PlannerStore: ObservableObject {
    @Published private(set) var entries: [PlannerEntry] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var isSaving = false
    @Published private(set) var streakCelebration: Int?
    private let storageKey = "task-manager.planner-entries"
    private let pendingStorageKey = "task-manager.pending-planner-entry-ids"
    private var pendingEntryIDs: Set<UUID> = []
    private let api = SpringBootAPIClient()

    init() {
        loadLocal()
        loadPendingIDs()
    }

    func entries(on day: Date) -> [PlannerEntry] {
        entries.filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: day) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var completedPlannerItems: [PlannerEntry] {
        entries.filter { $0.entryType != .note && $0.isComplete }
    }

    func trackableItems(inWeekStarting weekStart: Date) -> [PlannerEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStart)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return entries.filter {
            $0.entryType != .note && $0.scheduledAt >= start && $0.scheduledAt < end
        }
    }

    func progress(inWeekStarting weekStart: Date) -> Double {
        let items = trackableItems(inWeekStarting: weekStart)
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.isComplete).count) / Double(items.count)
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let completedDays = Set(completedPlannerItems.map { calendar.startOfDay(for: $0.scheduledAt) })
        guard !completedDays.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: Date.now)
        if !completedDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), completedDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while completedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let days = Set(completedPlannerItems.map { calendar.startOfDay(for: $0.scheduledAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for index in 1..<days.count {
            if calendar.dateComponents([.day], from: days[index - 1], to: days[index]).day == 1 { run += 1 }
            else { run = 1 }
            best = max(best, run)
        }
        return best
    }

    var sevenDayAverage: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let items = entries.filter { $0.entryType != .note && $0.scheduledAt >= start && $0.scheduledAt < calendar.date(byAdding: .day, value: 1, to: today)! }
        guard !items.isEmpty else { return 0 }
        return Int((Double(items.filter(\.isComplete).count) / Double(items.count)) * 100)
    }

    func add(title: String, details: String, type: PlannerEntryType, scheduledAt: Date) {
        let entry = PlannerEntry(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                 details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                                 entryType: type, scheduledAt: scheduledAt)
        entries.append(entry); saveLocal(); markPending(entry.id)
    }

    func add(title: String, details: String, type: PlannerEntryType, dates: [Date]) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let newEntries = dates.map {
            PlannerEntry(title: cleanTitle, details: cleanDetails, entryType: type, scheduledAt: $0)
        }
        entries.append(contentsOf: newEntries)
        saveLocal()
        newEntries.forEach { markPending($0.id) }
    }

    func toggle(_ entry: PlannerEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].isComplete.toggle(); saveLocal(); markPending(entry.id)
        if entries[index].isComplete {
            streakCelebration = max(currentStreak, 1)
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                streakCelebration = nil
            }
        }
    }

    func delete(_ entry: PlannerEntry) {
        entries.removeAll { $0.id == entry.id }; saveLocal()
        Task { await api.deletePlannerEntry(entry.id) }
    }

    func saveWeek(starting weekStart: Date) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStart)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        let weekEntries = entries.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
        weekEntries.forEach { markPending($0.id) }
        var allSaved = true
        for entry in weekEntries {
            let saved = await api.upsertPlannerEntry(entry)
            if saved { markSynced(entry.id) } else { allSaved = false; break }
        }
        if allSaved {
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
                let items = entries(on: day).filter { $0.entryType != .note }
                let completed = items.filter(\.isComplete).count
                let percent = items.isEmpty ? 0 : Int(Double(completed) / Double(items.count) * 100)
                let saved = await api.saveDailyProgress(
                    date: day, scheduledCount: items.count, completedCount: completed,
                    completionPercent: percent, currentStreak: currentStreak
                )
                if !saved { allSaved = false; break }
            }
        }
        return allSaved
    }

    func sync(weekStart: Date) async {
        isSyncing = true
        defer { isSyncing = false }
        await flushPendingEntries()
        if let remote = try? await api.plannerEntries(weekStart: weekStart) {
            let remoteIDs = Set(remote.map(\.id))
            let start = Calendar.current.startOfDay(for: weekStart)
            let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
            entries.removeAll {
                $0.scheduledAt >= start && $0.scheduledAt < end
                    && !remoteIDs.contains($0.id) && !pendingEntryIDs.contains($0.id)
            }
            for entry in remote {
                if let index = entries.firstIndex(where: { $0.id == entry.id }) { entries[index] = entry }
                else { entries.append(entry) }
            }
            saveLocal()
        }
    }

    private func loadLocal() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PlannerEntry].self, from: data) else { return }
        entries = decoded
    }
    private func saveLocal() {
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
    private func loadPendingIDs() {
        let values = UserDefaults.standard.stringArray(forKey: pendingStorageKey) ?? []
        pendingEntryIDs = Set(values.compactMap(UUID.init(uuidString:)))
    }
    private func markPending(_ id: UUID) {
        pendingEntryIDs.insert(id)
        savePendingIDs()
    }
    private func markSynced(_ id: UUID) {
        pendingEntryIDs.remove(id)
        savePendingIDs()
    }
    private func savePendingIDs() {
        UserDefaults.standard.set(pendingEntryIDs.map(\.uuidString), forKey: pendingStorageKey)
    }
    private func flushPendingEntries() async {
        let queued = entries.filter { pendingEntryIDs.contains($0.id) }
        for entry in queued {
            if await api.upsertPlannerEntry(entry) { markSynced(entry.id) }
            else { break }
        }
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
    @Published private(set) var profileImageURL: URL?

    private let nameKey = "task-manager.user-name"
    private let emailKey = "task-manager.user-email"
    private let syncClient = SpringBootAPIClient()

    init() {
        let storedName = UserDefaults.standard.string(forKey: nameKey) ?? ""
        let storedEmail = UserDefaults.standard.string(forKey: emailKey) ?? ""
        userName = storedName
        email = storedEmail
        profileImageURL = nil
        isAuthenticated = !storedName.isEmpty
        if isAuthenticated {
            Task { [weak self] in await self?.restoreBackendSession() }
        }
    }

    func signIn(name: String, email: String, password: String, mode: AuthMode) async throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedName = cleanName.isEmpty ? "Task Manager User" : cleanName
        let account = AuthAccount(name: requestedName, email: cleanEmail, password: password, mode: mode.rawValue)
        let authenticatedUser = try await syncClient.authenticate(account: account)

        userName = authenticatedUser.name
        self.email = authenticatedUser.email
        isAuthenticated = true
        UserDefaults.standard.set(userName, forKey: nameKey)
        UserDefaults.standard.set(authenticatedUser.email, forKey: emailKey)
        await refreshProfileImage()
    }

    func signOut() {
        userName = ""
        email = ""
        isAuthenticated = false
        profileImageURL = nil
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }

    func uploadProfileImage(data: Data, contentType: String, fileExtension: String) async throws {
        guard !email.isEmpty else { throw SpringBootAPIClient.APIError.authenticationFailed("Sign in before uploading a profile image.") }
        profileImageURL = try await syncClient.uploadProfileImage(
            data: data,
            ownerEmail: email,
            contentType: contentType,
            fileExtension: fileExtension
        )
    }

    func refreshProfileImage() async {
        guard !email.isEmpty else { return }
        profileImageURL = try? await syncClient.profileImageURL(ownerEmail: email)
    }

    private func restoreBackendSession() async {
        do {
            let user = try await syncClient.validateSession(email: email)
            userName = user.name
            email = user.email
            await refreshProfileImage()
        } catch {
            // Old app versions trusted UserDefaults without creating a backend
            // account. Clear that stale state and require a real sign-in once.
            signOut()
        }
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

struct SpringBootAPIClient {
    private var baseURL: URL? {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "SPRING_BOOT_API_URL") as? String
        return URL(string: configuredURL?.isEmpty == false ? configuredURL! : "http://localhost:8080/api")
    }

    func upsert(task: TaskItem) async {
        guard let email = UserDefaults.standard.string(forKey: "task-manager.user-email"), !email.isEmpty else { return }
        let payload = TaskUpsertPayload(ownerEmail: email, task: task)
        await send(path: "tasks/\(task.id.uuidString)", method: "PUT", payload: payload)
    }

    func authenticate(account: AuthAccount) async throws -> AuthResponse {
        guard let endpoint = baseURL?.appending(path: "auth") else { throw APIError.invalidURL }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(account)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.authenticationFailed(httpResponse.statusCode == 401 ? "Incorrect email or password." : "Unable to authenticate with the server.")
        }
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func validateSession(email: String) async throws -> AuthResponse {
        guard var components = URLComponents(url: baseURL?.appending(path: "auth/session") ?? URL(fileURLWithPath: ""), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components.url else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.authenticationFailed("Your saved session is no longer valid.")
        }
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func uploadProfileImage(data: Data, ownerEmail: String, contentType: String, fileExtension: String) async throws -> URL {
        let fileName = "profile-\(UUID().uuidString).\(fileExtension)"
        let uploadRequest = UploadURLRequest(ownerEmail: ownerEmail, fileName: fileName, contentType: contentType)
        let upload: UploadURLResponse = try await request(path: "storage/upload-url", method: "POST", payload: uploadRequest)
        guard let uploadURL = URL(string: upload.uploadUrl) else { throw APIError.invalidURL }

        var s3Request = URLRequest(url: uploadURL)
        s3Request.httpMethod = "PUT"
        s3Request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let (_, uploadResponse) = try await URLSession.shared.upload(for: s3Request, from: data)
        guard let httpResponse = uploadResponse as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.uploadFailed
        }

        let saveRequest = ProfileImageRequest(ownerEmail: ownerEmail, objectKey: upload.objectKey)
        let _: ObjectKeyResponse = try await request(path: "storage/profile-image", method: "PUT", payload: saveRequest)
        guard let url = try await profileImageURL(ownerEmail: ownerEmail) else { throw APIError.invalidResponse }
        return url
    }

    func profileImageURL(ownerEmail: String) async throws -> URL? {
        guard var components = URLComponents(url: baseURL?.appending(path: "storage/profile-image-url") ?? URL(fileURLWithPath: ""), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "email", value: ownerEmail)]
        guard let url = components.url else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        let result = try JSONDecoder().decode(ProfileImageURLResponse.self, from: data)
        guard let value = result.downloadUrl else { return nil }
        return URL(string: value)
    }

    func plannerEntries(weekStart: Date) async throws -> [PlannerEntry] {
        guard let email = UserDefaults.standard.string(forKey: "task-manager.user-email"), !email.isEmpty,
              var components = URLComponents(url: baseURL?.appending(path: "planner") ?? URL(fileURLWithPath: ""), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "weekStart", value: Self.isoFormatter.string(from: weekStart))
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw APIError.invalidResponse }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PlannerEntry].self, from: data)
    }

    func upsertPlannerEntry(_ entry: PlannerEntry) async -> Bool {
        guard let email = UserDefaults.standard.string(forKey: "task-manager.user-email"), !email.isEmpty else { return false }
        let payload = PlannerPayload(ownerEmail: email, entry: entry)
        return await send(path: "planner/\(entry.id.uuidString)", method: "PUT", payload: payload)
    }

    func deletePlannerEntry(_ id: UUID) async {
        guard let email = UserDefaults.standard.string(forKey: "task-manager.user-email"), !email.isEmpty,
              var components = URLComponents(url: baseURL?.appending(path: "planner/\(id.uuidString)") ?? URL(fileURLWithPath: ""), resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components.url else { return }
        var request = URLRequest(url: url); request.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: request)
    }

    func saveDailyProgress(date: Date, scheduledCount: Int, completedCount: Int,
                           completionPercent: Int, currentStreak: Int) async -> Bool {
        guard let email = UserDefaults.standard.string(forKey: "task-manager.user-email"), !email.isEmpty else { return false }
        let payload = DailyProgressPayload(
            ownerEmail: email, date: Self.dayFormatter.string(from: date), scheduledCount: scheduledCount,
            completedCount: completedCount, completionPercent: completionPercent, currentStreak: currentStreak
        )
        return await send(path: "progress/daily", method: "PUT", payload: payload)
    }

    private func request<Request: Encodable, Response: Decodable>(path: String, method: String, payload: Request) async throws -> Response {
        guard let endpoint = baseURL?.appending(path: path) else { throw APIError.invalidURL }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage(from: data))
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func serverMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (object["detail"] as? String) ?? (object["message"] as? String) ?? (object["error"] as? String)
    }

    @discardableResult
    private func send<T: Encodable>(path: String, method: String, payload: T) async -> Bool {
        guard let endpoint = baseURL?.appending(path: path) else { return false }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var request = URLRequest(url: endpoint)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Spring Boot sync failed: invalid HTTP response")
                return false
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = serverMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                print("Spring Boot sync failed (HTTP \(httpResponse.statusCode)): \(message)")
                return false
            }
            return true
        } catch {
            print("Spring Boot sync failed: \(error.localizedDescription)")
            return false
        }
    }

    private struct TaskUpsertPayload: Encodable {
        let ownerEmail: String
        let title: String
        let description: String
        let dueDate: Date
        let priority: String
        let category: String
        let reminderEnabled: Bool
        let isComplete: Bool
        let createdAt: Date

        init(ownerEmail: String, task: TaskItem) {
            self.ownerEmail = ownerEmail
            title = task.title
            description = task.description
            dueDate = task.dueDate
            priority = task.priority.rawValue
            category = task.category
            reminderEnabled = task.reminderEnabled
            isComplete = task.isComplete
            createdAt = task.createdAt
        }
    }

    private struct PlannerPayload: Encodable {
        let ownerEmail: String
        let title: String
        let details: String
        let entryType: String
        let scheduledAt: Date
        let isComplete: Bool
        let createdAt: Date
        init(ownerEmail: String, entry: PlannerEntry) {
            self.ownerEmail = ownerEmail; title = entry.title; details = entry.details
            entryType = entry.entryType.rawValue; scheduledAt = entry.scheduledAt
            isComplete = entry.isComplete; createdAt = entry.createdAt
        }
    }

    private struct DailyProgressPayload: Encodable {
        let ownerEmail: String
        let date: String
        let scheduledCount: Int
        let completedCount: Int
        let completionPercent: Int
        let currentStreak: Int
    }

    private static let isoFormatter = ISO8601DateFormatter()
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    struct AuthResponse: Decodable {
        let id: Int
        let name: String
        let email: String
        let provider: String
    }

    private struct UploadURLRequest: Encodable { let ownerEmail: String; let fileName: String; let contentType: String }
    private struct UploadURLResponse: Decodable { let uploadUrl: String; let objectKey: String; let contentType: String }
    private struct ProfileImageRequest: Encodable { let ownerEmail: String; let objectKey: String }
    private struct ObjectKeyResponse: Decodable { let objectKey: String }
    private struct ProfileImageURLResponse: Decodable { let downloadUrl: String?; let objectKey: String? }

    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case authenticationFailed(String)
        case uploadFailed
        case serverError(statusCode: Int, message: String?)

        var errorDescription: String? {
            switch self {
            case .invalidURL: "The backend URL is invalid."
            case .invalidResponse: "The backend returned an invalid response."
            case .authenticationFailed(let message): message
            case .uploadFailed: "The image could not be uploaded to Amazon S3."
            case .serverError(let statusCode, let message):
                if statusCode == 401 {
                    "Your backend session is not valid. Sign out, create/sign in to your account again, and retry."
                } else if statusCode == 403 {
                    "The backend or S3 denied access. Check the IAM permissions for this bucket."
                } else {
                    message ?? "The backend returned HTTP \(statusCode)."
                }
            }
        }
    }
}

enum AppTheme {
    static let blue = Color(red: 0.20, green: 0.36, blue: 0.92)
    static let indigo = Color(red: 0.42, green: 0.24, blue: 0.88)
    static let accentGradient = LinearGradient(colors: [blue, indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
            : UIColor(red: 0.965, green: 0.97, blue: 0.985, alpha: 1)
    })
    static let card = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1)
            : UIColor.white
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
    static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.07)
            : UIColor(red: 0.84, green: 0.86, blue: 0.92, alpha: 0.55)
    })
}
