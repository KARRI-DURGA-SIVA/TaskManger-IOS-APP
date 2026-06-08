import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    private let filters = ["All", "Today", "Upcoming", "Completed"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tasks")
                            .font(.system(size: 31, weight: .bold))
                        Text(settings.focusMode ? "Focus Mode: high priority first" : "\(taskStore.activeTasks.count) active tasks")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    Spacer()
                }
                .padding(.top, 56)

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.mutedText)
                    TextField("Search tasks, category, or priority", text: $searchText)
                        .font(.system(size: 15, weight: .semibold))
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.mutedText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(CardBackground(radius: 8))

                PrioritySummaryStrip(tasks: filteredTasks)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(selectedFilter == filter ? .white : .black)
                                    .frame(minWidth: 58)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(selectedFilter == filter ? AppTheme.blue : AppTheme.card)
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(selectedFilter == filter ? 0.18 : 0.04), radius: 4, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .overlay(alignment: .bottomLeading) {
                    Capsule()
                        .fill(.black.opacity(0.24))
                        .frame(width: 334, height: 7)
                        .padding(.leading, -20)
                }

                if filteredTasks.isEmpty {
                    EmptyStateView(title: searchText.isEmpty ? "No \(selectedFilter.lowercased()) tasks" : "No matching tasks", subtitle: "Tap plus to create a task with date, priority, category, and reminder.")
                } else {
                    ForEach(PriorityLevel.allCases, id: \.self) { priority in
                        let tasks = filteredTasks.filter { $0.priority == priority }
                        if !tasks.isEmpty {
                            TaskSection(title: "\(priority.rawValue.uppercased()) PRIORITY", tasks: tasks)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
    }

    private var filteredTasks: [TaskItem] {
        let sortedTasks = taskStore.tasks.sorted {
            if settings.focusMode, $0.priority != $1.priority {
                return priorityRank($0.priority) < priorityRank($1.priority)
            }
            return $0.dueDate < $1.dueDate
        }
        switch selectedFilter {
        case "Today":
            return search(sortedTasks.filter(\.isToday))
        case "Upcoming":
            return search(sortedTasks.filter { !$0.isComplete && $0.dueDate >= Date.now })
        case "Completed":
            return search(sortedTasks.filter(\.isComplete))
        default:
            return search(sortedTasks)
        }
    }

    private func search(_ tasks: [TaskItem]) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return tasks }

        return tasks.filter { task in
            task.title.lowercased().contains(query) ||
            task.description.lowercased().contains(query) ||
            task.category.lowercased().contains(query) ||
            task.priority.rawValue.lowercased().contains(query)
        }
    }

    private func priorityRank(_ priority: PriorityLevel) -> Int {
        switch priority {
        case .high:
            0
        case .medium:
            1
        case .low:
            2
        }
    }
}

struct PrioritySummaryStrip: View {
    let tasks: [TaskItem]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(PriorityLevel.allCases, id: \.self) { priority in
                VStack(alignment: .leading, spacing: 4) {
                    Text(priority.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.mutedText)
                    Text("\(tasks.filter { $0.priority == priority }.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(priority == .high ? .red : (priority == .medium ? AppTheme.blue : AppTheme.success))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(CardBackground(radius: 8))
            }
        }
    }
}

struct TaskSection: View {
    @EnvironmentObject private var taskStore: TaskStore
    let title: String
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
            ForEach(tasks) { task in
                TaskRow(task: task) {
                    taskStore.toggleComplete(task)
                }
            }
        }
    }
}

struct TaskRow: View {
    let title: String
    let subtitle: String
    var isComplete = false
    var onToggle: () -> Void = {}

    init(title: String, subtitle: String, isComplete: Bool = false, onToggle: @escaping () -> Void = {}) {
        self.title = title
        self.subtitle = subtitle
        self.isComplete = isComplete
        self.onToggle = onToggle
    }

    init(task: TaskItem, onToggle: @escaping () -> Void = {}) {
        self.title = task.title
        self.subtitle = task.subtitle
        self.isComplete = task.isComplete
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(AppTheme.blue)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .strikethrough(isComplete, color: .black.opacity(0.45))
                    .foregroundStyle(isComplete ? .black.opacity(0.58) : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(isComplete ? .black.opacity(0.60) : .black)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(CardBackground(radius: 16))
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist.unchecked")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.blue)
            Text(title)
                .font(.system(size: 17, weight: .bold))
            Text(subtitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(CardBackground(radius: 16))
    }
}
