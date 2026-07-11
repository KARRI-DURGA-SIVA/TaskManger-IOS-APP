import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var settings: AppSettings
    @FocusState private var focusedField: Field?

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var priority: PriorityLevel = .high
    @State private var category = "Work"
    @State private var remindersEnabled = true

    private enum Field {
        case title
        case description
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 18) {
                            TextField("What needs to be done?", text: $title)
                                .font(.system(size: 21, weight: .bold))
                                .focused($focusedField, equals: .title)

                            TextEditor(text: $description)
                                .font(.system(size: 15))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 112)
                                .overlay(alignment: .topLeading) {
                                    if description.isEmpty {
                                        Text("Add notes or description...")
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppTheme.mutedText)
                                            .padding(.top, 8)
                                            .padding(.leading, 5)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .focused($focusedField, equals: .description)
                        }
                        .padding(26)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(CardBackground(radius: 24))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.softBlue)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(AppTheme.blue)
                                    }
                                DatePicker("Date & Time", selection: $dueDate)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 82)
                        .background(CardBackground(radius: 18))

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Priority")
                                    .font(.system(size: 16, weight: .bold))
                                Text(priority.rawValue)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(PriorityLevel.allCases, id: \.self) { level in
                                    Button {
                                        priority = level
                                    } label: {
                                        Text(String(level.rawValue.prefix(1)))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(priority == level ? AppTheme.text : .white)
                                            .frame(width: 34, height: 34)
                                            .background(priority == level ? AppTheme.rail.opacity(0.45) : AppTheme.blue)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 26)
                        .frame(height: 74)
                        .background(CardBackground(radius: 18))

                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.softGreen)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "tag.fill")
                                        .foregroundStyle(AppTheme.success)
                                }

                            Picker("Category", selection: $category) {
                                ForEach(taskStore.categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .pickerStyle(.menu)

                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 74)
                        .background(CardBackground(radius: 18))

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Reminders")
                                    .font(.system(size: 16, weight: .bold))
                                Text(remindersEnabled ? "Enabled" : "Disabled")
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            Toggle("", isOn: $remindersEnabled)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 26)
                        .frame(height: 74)
                        .background(CardBackground(radius: 18))

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 34)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                category = taskStore.categories.contains(settings.defaultCategory)
                    ? settings.defaultCategory
                    : taskStore.categories.first ?? "Work"
                remindersEnabled = settings.notificationsEnabled
                focusedField = .title
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        taskStore.addTask(
                            title: title,
                            description: description,
                            dueDate: dueDate,
                            priority: priority,
                            category: category,
                            reminderEnabled: remindersEnabled
                        )
                        dismiss()
                    }
                        .font(.system(size: 16, weight: .semibold))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct FormOptionRow: View {
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconColor)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(detail)
                    .font(.system(size: 14))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(CardBackground(radius: 18))
    }
}
