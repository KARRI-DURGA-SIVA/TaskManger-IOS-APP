import PhotosUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @State private var activeSheet: SettingsSheet?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Spacer()
                    AvatarView(size: 42, imageURL: authStore.profileImageURL)
                }
                .padding(.top, 56)

                VStack(spacing: 14) {
                    ProfilePhotoSection()
                    SettingsToggleRow(iconName: "bell.fill", iconColor: AppTheme.blue, title: "Notifications", subtitle: "Daily reminders and task alerts", isOn: $settings.notificationsEnabled)
                    SettingsToggleRow(iconName: "moon.fill", iconColor: .purple, title: "Focus Mode", subtitle: "Highlight high priority tasks first", isOn: $settings.focusMode)
                    SettingsToggleRow(iconName: "icloud.fill", iconColor: AppTheme.success, title: "iCloud Sync", subtitle: settings.iCloudStatus, isOn: $settings.iCloudSyncEnabled)
                }

                VStack(spacing: 14) {
                    SettingsLinkRow(iconName: "tag.fill", iconColor: AppTheme.blue, title: "Default Category", value: settings.defaultCategory) {
                        activeSheet = .defaultCategory
                    }
                    SettingsLinkRow(iconName: "clock.fill", iconColor: .orange, title: "Daily Reminder", value: settings.dailyReminder.formatted(.dateTime.hour().minute())) {
                        activeSheet = .dailyReminder
                    }
                    SettingsLinkRow(iconName: "paintpalette.fill", iconColor: .pink, title: "Appearance", value: settings.appearance.rawValue) {
                        activeSheet = .appearance
                    }
                }

                Button {
                    authStore.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(CardBackground(radius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
        }
        .background(AppTheme.background)
        .sheet(item: $activeSheet) { sheet in
            SettingsDetailSheet(sheet: sheet)
                .environmentObject(taskStore)
                .environmentObject(settings)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

enum SettingsSheet: String, Identifiable {
    case defaultCategory
    case dailyReminder
    case appearance

    var id: String { rawValue }
}

struct SettingsDetailSheet: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let sheet: SettingsSheet

    var body: some View {
        NavigationStack {
            Form {
                switch sheet {
                case .defaultCategory:
                    Section("Choose Category") {
                        Picker("Default Category", selection: $settings.defaultCategory) {
                            ForEach(taskStore.categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                case .dailyReminder:
                    Section("Reminder Time") {
                        DatePicker("Daily Reminder", selection: $settings.dailyReminder, displayedComponents: .hourAndMinute)
                    }
                case .appearance:
                    Section("Theme") {
                        Picker("Appearance", selection: $settings.appearance) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var title: String {
        switch sheet {
        case .defaultCategory:
            "Default Category"
        case .dailyReminder:
            "Daily Reminder"
        case .appearance:
            "Appearance"
        }
    }
}

struct SettingsProfileHeader: View {
    let name: String
    let email: String

    var body: some View {
        HStack(spacing: 16) {
            AvatarView(size: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 18, weight: .bold))
                Text(email.isEmpty ? "Productivity workspace" : email)
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

struct ProfilePhotoSection: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var uploadError: String?

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(size: 88, imageURL: authStore.profileImageURL)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.accentGradient, in: Circle())
                        .overlay(Circle().stroke(AppTheme.card, lineWidth: 3))
                }
                .disabled(isUploading)
            }

            VStack(spacing: 4) {
                Text(authStore.userName).font(.system(size: 20, weight: .bold, design: .rounded))
                Text(authStore.email.isEmpty ? "Productivity workspace" : authStore.email)
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.mutedText)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    if isUploading { ProgressView().controlSize(.small) }
                    Text(isUploading ? "Uploading to S3..." : "Change profile photo")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.blue)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(AppTheme.softBlue.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isUploading)
        }
        .padding(22)
        .background(CardBackground(radius: 24))
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            upload(item)
        }
        .alert("Profile Photo", isPresented: Binding(
            get: { uploadError != nil },
            set: { if !$0 { uploadError = nil } }
        )) { Button("OK", role: .cancel) {} } message: {
            Text(uploadError ?? "The photo could not be uploaded.")
        }
    }

    private func upload(_ item: PhotosPickerItem) {
        isUploading = true
        Task {
            defer {
                isUploading = false
                selectedPhoto = nil
            }
            do {
                guard let sourceData = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: sourceData),
                      let jpegData = image.jpegData(compressionQuality: 0.82) else {
                    throw ProfilePhotoError.invalidImage
                }
                try await authStore.uploadProfileImage(
                    data: jpegData,
                    contentType: "image/jpeg",
                    fileExtension: "jpg"
                )
            } catch {
                uploadError = error.localizedDescription
            }
        }
    }

    private enum ProfilePhotoError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "The selected photo could not be processed." }
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
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(.plain)
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
