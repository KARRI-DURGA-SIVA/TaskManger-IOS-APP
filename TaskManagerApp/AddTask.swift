import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var priority: PriorityLevel = .high
    @State private var remindersEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("What needs to be done?")
                                .font(.system(size: 21, weight: .bold))
                            Text("Add notes or description...")
                                .font(.system(size: 14))
                            Spacer(minLength: 54)
                        }
                        .padding(26)
                        .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
                        .background(CardBackground(radius: 24))

                        FormOptionRow(iconColor: AppTheme.softBlue, title: "Date & Time", detail: "Today, 2:00 PM")

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
                                            .foregroundStyle(priority == level ? .black : .white)
                                            .frame(width: 34, height: 34)
                                            .background(priority == level ? Color.black.opacity(0.09) : AppTheme.blue)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 26)
                        .frame(height: 74)
                        .background(CardBackground(radius: 18))

                        FormOptionRow(iconColor: AppTheme.softGreen, title: "Category", detail: "Work")

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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
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
