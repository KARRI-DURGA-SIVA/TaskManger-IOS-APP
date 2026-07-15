import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plannerStore: PlannerStore
    @State private var showingCategories = false
    @State private var focusTask: TaskItem?
    @State private var showingPlanner = false
    var onViewTasks: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                dashboardHeader

                if let suggestedTask {
                    FocusRecommendationCard(task: suggestedTask) {
                        focusTask = suggestedTask
                    }
                } else {
                    DailyProgressCard()
                }

                todaySnapshot

                ConsistencyMotivationCard()

                WeeklyWorkspaceCard {
                    showingPlanner = true
                }

                SectionHeader(title: "Spaces", action: "See all") {
                    showingCategories = true
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(taskStore.categorySummaries()) { category in
                            CategoryTile(category: category)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .contentMargins(.horizontal, 24, for: .scrollContent)
                .padding(.horizontal, -24)

                SectionHeader(title: "Next up", action: "View tasks", onAction: onViewTasks)

                VStack(alignment: .leading, spacing: 18) {
                    if taskStore.activeTasks.isEmpty {
                        EmptyStateView(title: "Your day is clear", subtitle: "Create a task when you’re ready to make progress.")
                    } else {
                        if !todayTasks.isEmpty {
                            NextUpGroupHeader(title: "Today", count: todayTasks.count, color: .orange)
                            ForEach(todayTasks.prefix(3)) { task in TaskRow(task: task) { taskStore.toggleComplete(task) } }
                        }
                        if !laterTasks.isEmpty {
                            NextUpGroupHeader(title: "Coming up", count: laterTasks.count, color: AppTheme.blue)
                            ForEach(laterTasks.prefix(3)) { task in TaskRow(task: task) { taskStore.toggleComplete(task) } }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 116)
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showingCategories) {
            CategorySectionsView()
                .environmentObject(taskStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $focusTask) { task in
            FocusSprintView(task: task)
                .environmentObject(taskStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPlanner) {
            WeeklyPlannerView()
                .environmentObject(plannerStore)
        }
    }

    private var dashboardHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.blue)
                Text(firstName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            AvatarView(size: 48, imageURL: authStore.profileImageURL)
        }
        .padding(.top, 54)
    }

    private var todaySnapshot: some View {
        let plannerItems = plannerStore.entries(on: Date.now).filter { $0.entryType != .note }
        let todayTasks = taskStore.tasks.filter(\.isToday)
        let completed = plannerItems.filter(\.isComplete).count + todayTasks.filter(\.isComplete).count
        let total = plannerItems.count + todayTasks.count
        let progress = total == 0 ? 0 : Int(Double(completed) / Double(total) * 100)
        return HStack(spacing: 0) {
            SnapshotMetric(value: "\(total)", label: "Scheduled", icon: "sun.max.fill", color: .orange)
            Divider().frame(height: 42)
            SnapshotMetric(value: "\(completed)", label: "Finished", icon: "checkmark.circle.fill", color: AppTheme.success)
            Divider().frame(height: 42)
            SnapshotMetric(value: "\(progress)%", label: "Today", icon: "chart.line.uptrend.xyaxis", color: AppTheme.blue)
        }
        .padding(.vertical, 18)
        .background(CardBackground(radius: 22))
    }

    private var todayTasks: [TaskItem] { taskStore.activeTasks.filter(\.isToday).sorted { $0.dueDate < $1.dueDate } }
    private var laterTasks: [TaskItem] { taskStore.activeTasks.filter { !$0.isToday }.sorted { $0.dueDate < $1.dueDate } }

    private var suggestedTask: TaskItem? {
        taskStore.activeTasks.sorted {
            let lhs = priorityRank($0.priority)
            let rhs = priorityRank($1.priority)
            return lhs == rhs ? $0.dueDate < $1.dueDate : lhs < rhs
        }.first
    }

    private func priorityRank(_ priority: PriorityLevel) -> Int {
        switch priority { case .high: 0; case .medium: 1; case .low: 2 }
    }

    private var firstName: String {
        authStore.userName.split(separator: " ").first.map(String.init) ?? "Welcome"
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date.now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}

struct ConsistencyMotivationCard: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.orange.opacity(0.14)).frame(width: 52, height: 52)
                Image(systemName: "flame.fill").font(.system(size: 25, weight: .bold)).foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(plannerStore.currentStreak == 0 ? "Start your streak today" : "\(plannerStore.currentStreak)-day consistency streak")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text("Best \(plannerStore.bestStreak) days • 7-day average \(plannerStore.sevenDayAverage)%")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            Image(systemName: "chevron.up").font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.success)
        }
        .padding(18).background(CardBackground(radius: 21))
    }
}

struct NextUpGroupHeader: View {
    let title: String
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.2)
            Text("\(count)").font(.system(size: 10, weight: .bold)).foregroundStyle(AppTheme.mutedText)
            Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5)
        }
    }
}

struct WeeklyWorkspaceCard: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("WEEKLY WORKSPACE", systemImage: "rectangle.3.group")
                        .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundStyle(AppTheme.indigo)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.mutedText)
                }
                HStack(spacing: 7) {
                    ForEach(currentWeek, id: \.self) { day in
                        VStack(spacing: 7) {
                            Text(day.formatted(.dateTime.weekday(.narrow))).font(.system(size: 10, weight: .bold))
                            Circle()
                                .fill(plannerStore.entries(on: day).isEmpty ? AppTheme.rail.opacity(0.45) : AppTheme.indigo)
                                .frame(width: 8, height: 8)
                        }
                        .foregroundStyle(Calendar.current.isDateInToday(day) ? AppTheme.indigo : AppTheme.mutedText)
                        .frame(maxWidth: .infinity)
                    }
                }
                let progress = plannerStore.progress(inWeekStarting: currentWeek.first ?? Date.now)
                VStack(spacing: 7) {
                    HStack {
                        Text("This week’s progress").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
                        Spacer()
                        Text("\(Int(progress * 100))%").font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.success)
                    }
                    ProgressView(value: progress).tint(AppTheme.success)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Plan your week, your way").font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Activities, events, and notes from Sunday to Saturday")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.mutedText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right.circle.fill").font(.system(size: 25)).foregroundStyle(AppTheme.indigo)
                }
            }
            .padding(19).background(CardBackground(radius: 22))
        }.buttonStyle(.plain)
    }

    private var currentWeek: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let sunday = calendar.date(byAdding: .day, value: -(calendar.component(.weekday, from: today) - 1), to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }
}

struct FocusRecommendationCard: View {
    let task: TaskItem
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("SMART FOCUS", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.3)
                Spacer()
                Text("25 MIN")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.15), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Your best next move")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                Text(task.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .lineLimit(2)
                Text("\(task.category)  •  \(task.dueDate.formatted(.dateTime.hour().minute()))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.74))
            }

            Button(action: onStart) {
                Label("Start focus sprint", systemImage: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.08)).frame(width: 150).offset(x: 45, y: -65)
        }
        .clipped()
        .shadow(color: AppTheme.blue.opacity(0.22), radius: 20, y: 10)
    }
}

struct SnapshotMetric: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FocusSprintView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    @State private var secondsRemaining = 25 * 60
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 34) {
                Spacer()
                ZStack {
                    Circle().stroke(AppTheme.rail.opacity(0.5), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: CGFloat(secondsRemaining) / CGFloat(25 * 60))
                        .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 7) {
                        Text(timeText)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(isRunning ? "STAY WITH IT" : "READY WHEN YOU ARE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                }
                .frame(width: 250, height: 250)

                VStack(spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text("\(task.category) • \(task.priority.rawValue) priority")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedText)
                }

                Button { isRunning.toggle() } label: {
                    Label(isRunning ? "Pause sprint" : "Start sprint", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(.plain)

                Button("Mark task complete") {
                    taskStore.toggleComplete(task)
                    dismiss()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.blue)
                Spacer()
            }
            .padding(.horizontal, 30)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Focus Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .task(id: isRunning) {
                guard isRunning else { return }
                while !Task.isCancelled && secondsRemaining > 0 {
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled { secondsRemaining -= 1 }
                }
                if secondsRemaining == 0 { isRunning = false }
            }
        }
    }

    private var timeText: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }
}

struct DailyProgressCard: View {
    @EnvironmentObject private var taskStore: TaskStore
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("All caught up").font(.system(size: 20, weight: .bold))
                Text("You’ve completed \(taskStore.completedTasks.count) tasks.")
                    .font(.system(size: 14)).foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 42)).foregroundStyle(AppTheme.success)
        }
        .padding(22).background(CardBackground(radius: 24))
    }
}

struct CategorySectionsView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(taskStore.categorySummaries()) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label(category.name, systemImage: category.iconName).font(.system(size: 18, weight: .bold))
                                Spacer(); Text(category.count).font(.caption.bold()).foregroundStyle(AppTheme.mutedText)
                            }
                            let categoryTasks = taskStore.tasks(in: category.name)
                            if categoryTasks.isEmpty {
                                EmptyStateView(title: "No \(category.name.lowercased()) tasks", subtitle: "Tasks added to this space will appear here.")
                            } else {
                                ForEach(categoryTasks) { task in TaskRow(task: task) { taskStore.toggleComplete(task) } }
                            }
                        }
                    }
                }.padding(24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Spaces").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct CategoryTile: View {
    let category: CategorySummary
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: category.iconName)
                .font(.system(size: 17, weight: .bold)).foregroundStyle(AppTheme.blue)
                .frame(width: 40, height: 40).background(category.color, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(category.name).font(.system(size: 15, weight: .bold))
                Text(category.count).font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
            }
            ProgressView(value: category.progress).tint(AppTheme.blue)
        }
        .padding(17).frame(width: 148, height: 150, alignment: .leading)
        .background(CardBackground(radius: 20))
    }
}
