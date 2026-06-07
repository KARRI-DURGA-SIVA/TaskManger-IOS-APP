import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MONDAY, OCT 24")
                            .font(.system(size: 14, weight: .medium))
                            .textCase(.uppercase)
                        Text("Good Morning!")
                            .font(.system(size: 30, weight: .bold))
                    }

                    Spacer()

                    AvatarView(size: 48)
                }
                .padding(.top, 52)

                DailyProgressCard()

                SectionHeader(title: "Categories", action: "See All")

                HStack(spacing: 16) {
                    CategoryTile(name: "Work", count: "4 Tasks Today", color: AppTheme.softBlue, iconName: "briefcase.fill")
                    CategoryTile(name: "Personal", count: "6 Tasks Today", color: AppTheme.softGreen, iconName: "person.fill")
                }

                SectionHeader(title: "Upcoming", action: "View List")

                VStack(spacing: 12) {
                    TaskRow(title: "Review design system", subtitle: "10:00 AM · High Priority")
                    TaskRow(title: "Grocery shopping", subtitle: "05:30 PM · Personal")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 128)
        }
    }
}

struct DailyProgressCard: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Progress")
                    .font(.system(size: 18, weight: .bold))
                Text("8 of 12 tasks completed")
                    .font(.system(size: 15))

                ProgressView(value: 0.66)
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
                    .trim(from: 0, to: 0.66)
                    .stroke(AppTheme.blue, style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                Text("66%")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(width: 76, height: 76)
        }
        .padding(.horizontal, 26)
        .frame(height: 130)
        .background(CardBackground(radius: 24))
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
