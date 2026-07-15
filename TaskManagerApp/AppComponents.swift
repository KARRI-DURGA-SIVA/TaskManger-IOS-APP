import SwiftUI

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showingAddTask: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 2) {
                tabButton(.overview)
                tabButton(.tasks)
                Spacer(minLength: 62)
                tabButton(.stats)
                tabButton(.settings)
            }
            .padding(.horizontal, 10)
            .frame(height: 58)

            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.accentGradient)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))
                    .shadow(color: AppTheme.blue.opacity(0.28), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .offset(y: -8)
        }
        .frame(height: 58)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.cardBorder)
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                Text(tab.rawValue)
                    .font(.system(size: 9, weight: selectedTab == tab ? .bold : .medium))
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.blue : AppTheme.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
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
    var onAction: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 21, weight: .bold))
            Spacer()
            Button(action, action: onAction)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.blue)
        }
    }
}

struct AvatarView: View {
    let size: CGFloat
    var imageURL: URL? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.91, green: 0.92, blue: 0.94), Color(red: 0.58, green: 0.61, blue: 0.66)], startPoint: .top, endPoint: .bottom))
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white, lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white, Color(red: 0.12, green: 0.22, blue: 0.35))
            .padding(5)
    }
}

struct CardBackground: View {
    let radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(AppTheme.card)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 0.7)
            }
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}
