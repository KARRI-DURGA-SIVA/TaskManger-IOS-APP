import SwiftUI

struct AnalysisView: View {
    private let bars: [CGFloat] = [0.50, 0.80, 0.63, 0.34, 0.92, 0.42, 0.22]
    private let categories = [
        CategorySummary(name: "Work", count: "42 Tasks", color: AppTheme.softBlue, progress: 0.74),
        CategorySummary(name: "Personal", count: "35 Tasks", color: AppTheme.softGreen, progress: 0.66),
        CategorySummary(name: "Health", count: "14 Tasks", color: Color.black.opacity(0.04), progress: 0.0)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Analytics")
                        .font(.system(size: 31, weight: .bold))
                    Text("Your productivity this week")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.top, 56)

                VStack(spacing: 26) {
                    HStack {
                        Text("Completed Tasks")
                            .font(.system(size: 19, weight: .bold))
                        Spacer()
                        Picker("Range", selection: .constant("This Week")) {
                            Text("This Week").tag("This Week")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 116, height: 28)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Capsule())
                    }

                    BarChart(bars: bars)
                        .frame(height: 174)
                        .padding(.horizontal, 10)

                    Divider()

                    HStack {
                        MetricView(value: "91", label: "TOTAL TASKS", color: .black)
                        Divider().frame(height: 46)
                        MetricView(value: "84%", label: "SUCCESS RATE", color: AppTheme.success)
                        Divider().frame(height: 46)
                        MetricView(value: "13", label: "AVG/DAY", color: AppTheme.blue)
                    }
                }
                .padding(26)
                .background(CardBackground(radius: 24))

                Text("By Category")
                    .font(.system(size: 22, weight: .bold))

                VStack(spacing: 14) {
                    ForEach(categories) { category in
                        CategoryProgressRow(category: category)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
    }
}

struct BarChart: View {
    let bars: [CGFloat]
    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 22) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.blue)
                        .frame(width: 20, height: 160 * value)
                    Text(labels[index])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black.opacity(0.42))
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
}
