import SwiftUI

struct TaskListView: View {
    @State private var selectedFilter = "All"
    private let filters = ["All", "Today", "Upcoming", "Completed"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Text("Tasks")
                        .font(.system(size: 31, weight: .bold))
                    Spacer()
                    Button {} label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 42, height: 42)
                            .background(AppTheme.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 56)

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

                TaskSection(title: "HIGH PRIORITY", tasks: [
                    TaskItem(title: "Submit Project Proposal", subtitle: "Today · 2:00 PM", isComplete: false),
                    TaskItem(title: "Client Meeting", subtitle: "Today · 4:30 PM", isComplete: false)
                ])

                TaskSection(title: "LATER TODAY", tasks: [
                    TaskItem(title: "Morning Yoga", subtitle: "Completed at 8:00 AM", isComplete: true),
                    TaskItem(title: "Read \"Atomic Habits\"", subtitle: "Personal · 30 mins", isComplete: false)
                ])
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
    }
}

struct TaskSection: View {
    let title: String
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
            ForEach(tasks) { task in
                TaskRow(title: task.title, subtitle: task.subtitle, isComplete: task.isComplete)
            }
        }
    }
}

struct TaskRow: View {
    let title: String
    let subtitle: String
    var isComplete = false

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isComplete ? AppTheme.blue.opacity(0.72) : .clear)
                .stroke(AppTheme.blue, lineWidth: isComplete ? 0 : 2)
                .frame(width: 24, height: 24)

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
