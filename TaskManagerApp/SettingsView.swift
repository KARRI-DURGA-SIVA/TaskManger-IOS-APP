import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var focusMode = false
    @State private var syncEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 31, weight: .bold))
                    Spacer()
                    AvatarView(size: 42)
                }
                .padding(.top, 56)

                VStack(spacing: 14) {
                    SettingsProfileHeader()
                    SettingsToggleRow(iconName: "bell.fill", iconColor: AppTheme.blue, title: "Notifications", subtitle: "Task reminders and updates", isOn: $notificationsEnabled)
                    SettingsToggleRow(iconName: "moon.fill", iconColor: .purple, title: "Focus Mode", subtitle: "Mute low priority tasks", isOn: $focusMode)
                    SettingsToggleRow(iconName: "icloud.fill", iconColor: AppTheme.success, title: "iCloud Sync", subtitle: "Keep tasks updated", isOn: $syncEnabled)
                }

                VStack(spacing: 14) {
                    SettingsLinkRow(iconName: "tag.fill", iconColor: AppTheme.blue, title: "Default Category", value: "Work")
                    SettingsLinkRow(iconName: "clock.fill", iconColor: .orange, title: "Daily Reminder", value: "9:00 AM")
                    SettingsLinkRow(iconName: "paintpalette.fill", iconColor: .pink, title: "Appearance", value: "Light")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
    }
}

struct SettingsProfileHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            AvatarView(size: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text("Durga Siva")
                    .font(.system(size: 18, weight: .bold))
                Text("Productivity workspace")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(18)
        .background(CardBackground(radius: 20))
    }
}

struct SettingsToggleRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(iconName: iconName, color: iconColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .frame(height: 76)
        .background(CardBackground(radius: 18))
    }
}

struct SettingsLinkRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(iconName: iconName, color: iconColor)
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(.horizontal, 18)
        .frame(height: 68)
        .background(CardBackground(radius: 18))
    }
}

struct SettingsIcon: View {
    let iconName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.14))
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: 42, height: 42)
    }
}
