import SwiftUI

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showingAddTask: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: .black.opacity(0.05), radius: 10, y: -2)

            HStack {
                tabButton(.overview)
                tabButton(.tasks)
                Spacer(minLength: 86)
                tabButton(.stats)
                tabButton(.settings)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)

            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 70, height: 70)
                    .background(AppTheme.blue)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.blue.opacity(0.32), radius: 10, y: 8)
            }
            .buttonStyle(.plain)
            .offset(y: -18)
        }
        .frame(height: 104)
        .background(.white)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 7) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: selectedTab == tab ? .bold : .semibold))
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.blue : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .buttonStyle(.plain)
    }
}

extension AppTab {
    var iconName: String {
        switch self {
        case .overview:
            "square.grid.2x2"
        case .tasks:
            "list.bullet"
        case .stats:
            "chart.bar.xaxis"
        case .settings:
            "gearshape"
        }
    }
}

struct SectionHeader: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 21, weight: .bold))
            Spacer()
            Button(action) {}
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.blue)
        }
    }
}

struct AvatarView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.91, green: 0.92, blue: 0.94), Color(red: 0.58, green: 0.61, blue: 0.66)], startPoint: .top, endPoint: .bottom))
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white, Color(red: 0.12, green: 0.22, blue: 0.35))
                .padding(5)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white, lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
    }
}

struct CardBackground: View {
    let radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(AppTheme.card)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}
