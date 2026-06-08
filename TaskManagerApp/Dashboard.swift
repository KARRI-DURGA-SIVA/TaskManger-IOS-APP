import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var taskStore: TaskStore
    @State private var showingCategories = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    TimelineView(.periodic(from: Date.now, by: 60)) { context in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(context.date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.blue)
                            Text(context.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.system(size: 13, weight: .medium))
                                .textCase(.uppercase)
                                .foregroundStyle(AppTheme.mutedText)
                            Text(authStore.userName)
                                .font(.system(size: 30, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }

                    Spacer()

                    AvatarView(size: 48)
                }
                .padding(.top, 52)

                DailyProgressCard()

                SectionHeader(title: "Categories", action: "See All") {
                    showingCategories = true
                }

                HStack(spacing: 16) {
                    ForEach(Array(taskStore.categorySummaries().prefix(2))) { category in
                        CategoryTile(
                            name: category.name,
                            count: category.count,
                            color: category.color,
                            iconName: iconName(for: category.name)
                        )
                    }
                }

                SectionHeader(title: "Upcoming", action: "View List")

                VStack(spacing: 12) {
                    if taskStore.upcomingTasks.isEmpty {
                        EmptyStateView(title: "No tasks yet", subtitle: "Tap plus to add your first task.")
                    } else {
                        ForEach(taskStore.upcomingTasks.prefix(4)) { task in
                            TaskRow(task: task) {
                                taskStore.toggleComplete(task)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 128)
        }
        .sheet(isPresented: $showingCategories) {
            CategorySectionsView()
                .environmentObject(taskStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Work":
            "briefcase.fill"
        case "Personal":
            "person.fill"
        case "Health":
            "heart.fill"
        case "Learning":
            "book.fill"
        default:
            "tag.fill"
        }
    }
}

struct DailyProgressCard: View {
    @EnvironmentObject private var taskStore: TaskStore

    var body: some View {
        let total = taskStore.tasks.count
        let completed = taskStore.completedTasks.count
        let progress = taskStore.completionProgress

        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Progress")
                    .font(.system(size: 18, weight: .bold))
                Text("\(completed) of \(total) tasks completed")
                    .font(.system(size: 15))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(AppTheme.blue)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)
                    .frame(maxWidth: 160)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(AppTheme.rail, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.blue, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(width: 76, height: 76)
        }
        .padding(.horizontal, 26)
        .frame(height: 130)
        .background(CardBackground(radius: 24))
    }
}

struct CategorySectionsView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(taskStore.categorySummaries()) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(category.name)
                                    .font(.system(size: 20, weight: .bold))
                                Spacer()
                                Text(category.count)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.mutedText)
                            }

                            let categoryTasks = taskStore.tasks(in: category.name)
                            if categoryTasks.isEmpty {
                                EmptyStateView(title: "No \(category.name.lowercased()) tasks", subtitle: "New tasks in this category will appear here.")
                            } else {
                                ForEach(categoryTasks) { task in
                                    TaskRow(task: task) {
                                        taskStore.toggleComplete(task)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CategoryTile: View {
    let name: String
    let count: String
    let color: Color
    let iconName: String

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.blue)
            }
            .frame(width: 44, height: 44)
            Spacer()
            Text(name)
                .font(.system(size: 16, weight: .bold))
            Text(count)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(CardBackground(radius: 20))
    }
}
