import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @State private var selectedRange: StatsRange = .week

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Analytics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(selectedRange.subtitle)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.top, 60)

                VStack(spacing: 26) {
                    HStack {
                        Text(selectedRange.title)
                            .font(.system(size: 19, weight: .bold))
                        Spacer()
                        Picker("Range", selection: $selectedRange) {
                            ForEach(StatsRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 132, height: 32)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Capsule())
                    }

                    BarChart(bars: chartData.bars, labels: chartData.labels)
                        .frame(height: 174)
                        .padding(.horizontal, 10)

                    Divider()

                    HStack {
                        MetricView(value: "\(taskStore.tasks.count)", label: "TOTAL TASKS", color: AppTheme.text)
                        Divider().frame(height: 46)
                        MetricView(value: "\(Int(taskStore.completionProgress * 100))%", label: "SUCCESS RATE", color: AppTheme.success)
                        Divider().frame(height: 46)
                        MetricView(value: "\(averagePerDay)", label: "AVG/DAY", color: AppTheme.blue)
                    }
                }
                .padding(26)
                .background(CardBackground(radius: 24))

                Text("By Category")
                    .font(.system(size: 22, weight: .bold))

                VStack(spacing: 14) {
                    ForEach(taskStore.categorySummaries()) { category in
                        CategoryProgressRow(category: category)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
        .background(AppTheme.background)
    }

    private var chartData: (bars: [CGFloat], labels: [String]) {
        switch selectedRange {
        case .week:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date.now)
            let labels = (0..<7).compactMap { offset -> String? in
                guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
                return String(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1))
            }
            return completionBars(days: 7, labels: labels)
        case .month:
            return completionBars(days: 30, labels: ["1", "5", "10", "15", "20", "25", "30"])
        case .year:
            return monthlyCompletionBars()
        }
    }

    private func completionBars(days: Int, labels: [String]) -> (bars: [CGFloat], labels: [String]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let dates = (0..<days).compactMap { calendar.date(byAdding: .day, value: -(days - 1) + $0, to: today) }
        let counts = labels.indices.map { index in
            let start = index * dates.count / labels.count
            let end = (index + 1) * dates.count / labels.count
            let bucket = dates[start..<end]
            return bucket.reduce(0) { count, day in
                count + taskStore.completedTasks.filter { calendar.isDate($0.dueDate, inSameDayAs: day) }.count
            }
        }
        let maxCount = max(counts.max() ?? 0, 1)
        return (counts.map { max(CGFloat($0) / CGFloat(maxCount), 0.08) }, labels)
    }

    private func monthlyCompletionBars() -> (bars: [CGFloat], labels: [String]) {
        let calendar = Calendar.current
        let symbols = calendar.shortMonthSymbols
        let currentMonth = calendar.component(.month, from: Date.now)
        let labels = (0..<12).map { offset in
            let monthIndex = (currentMonth - 12 + offset + 12) % 12
            return String(symbols[monthIndex].prefix(1))
        }
        let counts = (0..<12).map { offset in
            guard let month = calendar.date(byAdding: .month, value: -11 + offset, to: Date.now) else { return 0 }
            let monthComponents = calendar.dateComponents([.month, .year], from: month)
            return taskStore.completedTasks.filter {
                let taskComponents = calendar.dateComponents([.month, .year], from: $0.dueDate)
                return taskComponents.month == monthComponents.month && taskComponents.year == monthComponents.year
            }.count
        }
        let maxCount = max(counts.max() ?? 0, 1)
        return (counts.map { max(CGFloat($0) / CGFloat(maxCount), 0.08) }, labels)
    }

    private var averagePerDay: Int {
        let days: Int
        switch selectedRange {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date.now)) ?? .distantPast
        let completedInRange = taskStore.completedTasks.filter { $0.dueDate >= start && $0.dueDate <= Date.now }.count
        return Int(ceil(Double(completedInRange) / Double(days)))
    }
}

struct BarChart: View {
    let bars: [CGFloat]
    let labels: [String]

    var body: some View {
        HStack(alignment: .bottom, spacing: bars.count > 7 ? 10 : 22) {
            ForEach(Array(zip(bars, labels).enumerated()), id: \.offset) { _, item in
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.blue)
                        .frame(width: bars.count > 7 ? 12 : 20, height: 160 * item.0)
                    Text(item.1)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

struct MetricView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryProgressRow: View {
    let category: CategorySummary

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(category.color)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: category.iconName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(iconColor)
                }

            Text(category.name)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(category.count)
                .font(.system(size: 15, weight: .bold))

            ProgressView(value: category.progress)
                .progressViewStyle(.linear)
                .tint(category.progress == 0 ? Color.clear : (category.name == "Personal" ? AppTheme.success : AppTheme.blue))
                .frame(width: 64)
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(CardBackground(radius: 16))
    }

    private var iconColor: Color {
        switch category.name {
        case "Personal":
            AppTheme.success
        case "Health":
            .red
        case "Finance":
            .orange
        default:
            AppTheme.blue
        }
    }
}
