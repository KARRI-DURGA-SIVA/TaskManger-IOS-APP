import SwiftUI

struct WeeklyPlannerView: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    @Environment(\.dismiss) private var dismiss
    @State private var weekStart = Date.sundayStart
    @State private var selectedDay = Date.now
    @State private var showingComposer = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    weekHeader
                    daySelector
                    dayCanvas
                }
                .padding(22)
                .padding(.bottom, 50)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Weekly workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingComposer = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingComposer) {
                PlannerComposerView(selectedDay: selectedDay)
                    .environmentObject(plannerStore)
                    .presentationDetents([.large])
            }
            .task(id: weekStart) { await plannerStore.sync(weekStart: weekStart) }
        }
    }

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("MY WEEK").font(.system(size: 11, weight: .bold)).tracking(1.5).foregroundStyle(AppTheme.blue)
                    Text(weekRange).font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Notes, plans, and moments in one calm space")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                if plannerStore.isSyncing { ProgressView() }
            }
            HStack(spacing: 12) {
                Button { moveWeek(-1) } label: { Label("Previous", systemImage: "chevron.left") }
                Spacer()
                Button("This week") { weekStart = .sundayStart; selectedDay = Date.now }
                Spacer()
                Button { moveWeek(1) } label: { Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly) }
            }
            .font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.blue)
        }
        .padding(20).background(CardBackground(radius: 24))
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(weekDays, id: \.self) { day in
                    Button { selectedDay = day } label: {
                        VStack(spacing: 7) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.system(size: 10, weight: .bold))
                            Text(day.formatted(.dateTime.day())).font(.system(size: 19, weight: .bold, design: .rounded))
                            Circle().fill(plannerStore.entries(on: day).isEmpty ? .clear : (isSelected(day) ? .white : AppTheme.blue)).frame(width: 4, height: 4)
                        }
                        .foregroundStyle(isSelected(day) ? .white : AppTheme.text)
                        .frame(width: 51, height: 76)
                        .background(isSelected(day) ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.card))
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay { RoundedRectangle(cornerRadius: 17).stroke(AppTheme.cardBorder, lineWidth: isSelected(day) ? 0 : 0.7) }
                    }.buttonStyle(.plain)
                }
            }.padding(.vertical, 3)
        }
    }

    private var dayCanvas: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDay.formatted(.dateTime.weekday(.wide))).font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(daySubtitle).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                Button { showingComposer = true } label: {
                    Label("New block", systemImage: "plus").font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 13).frame(height: 38).background(AppTheme.softBlue, in: Capsule())
                }.buttonStyle(.plain).foregroundStyle(AppTheme.blue)
            }

            if dayEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2").font(.system(size: 30)).foregroundStyle(AppTheme.blue)
                    Text("A fresh page").font(.system(size: 17, weight: .bold))
                    Text("Add an activity, event, or note for this day.").font(.system(size: 13)).foregroundStyle(AppTheme.mutedText)
                    Button("Add your first block") { showingComposer = true }.font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.blue)
                }.frame(maxWidth: .infinity).padding(.vertical, 38).background(CardBackground(radius: 22))
            } else {
                ForEach(dayEntries) { entry in
                    PlannerBlockView(entry: entry)
                }
            }
        }
    }

    private var dayEntries: [PlannerEntry] { plannerStore.entries(on: selectedDay) }
    private var weekDays: [Date] { (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) } }
    private var weekRange: String {
        guard let end = weekDays.last else { return "" }
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }
    private var daySubtitle: String {
        let complete = dayEntries.filter(\.isComplete).count
        return dayEntries.isEmpty ? selectedDay.formatted(.dateTime.month(.wide).day()) : "\(complete) of \(dayEntries.count) activities complete"
    }
    private func isSelected(_ day: Date) -> Bool { Calendar.current.isDate(day, inSameDayAs: selectedDay) }
    private func moveWeek(_ offset: Int) {
        if let date = Calendar.current.date(byAdding: .day, value: offset * 7, to: weekStart) { weekStart = date; selectedDay = date }
    }
}

struct PlannerBlockView: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    let entry: PlannerEntry
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button { if entry.entryType == .activity { plannerStore.toggle(entry) } } label: {
                Image(systemName: entry.entryType == .activity && entry.isComplete ? "checkmark.circle.fill" : entry.entryType.iconName)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(blockColor).frame(width: 30, height: 30)
            }.buttonStyle(.plain).disabled(entry.entryType != .activity)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.title).font(.system(size: 16, weight: .bold)).strikethrough(entry.isComplete)
                    Spacer()
                    if entry.entryType == .event { Text(entry.scheduledAt.formatted(.dateTime.hour().minute())).font(.caption.bold()).foregroundStyle(AppTheme.blue) }
                }
                if !entry.details.isEmpty { Text(entry.details).font(.system(size: 13)).foregroundStyle(AppTheme.mutedText).fixedSize(horizontal: false, vertical: true) }
                Text(entry.entryType.rawValue.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1.1).foregroundStyle(blockColor)
            }
        }
        .padding(17).background(CardBackground(radius: 18))
        .contextMenu { Button("Delete", role: .destructive) { plannerStore.delete(entry) } }
    }
    private var blockColor: Color { switch entry.entryType { case .activity: AppTheme.success; case .event: AppTheme.blue; case .note: .orange } }
}

struct PlannerComposerView: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    @Environment(\.dismiss) private var dismiss
    let selectedDay: Date
    @State private var title = ""
    @State private var details = ""
    @State private var type: PlannerEntryType = .activity
    @State private var scheduledAt: Date

    init(selectedDay: Date) {
        self.selectedDay = selectedDay
        _scheduledAt = State(initialValue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDay) ?? selectedDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Block type") {
                    Picker("Type", selection: $type) {
                        ForEach(PlannerEntryType.allCases, id: \.self) { Label($0.rawValue, systemImage: $0.iconName).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section(type == .note ? "Note" : "Plan") {
                    TextField(type == .note ? "Note title" : "What are you planning?", text: $title)
                    TextField("Details (optional)", text: $details, axis: .vertical).lineLimit(3...7)
                    DatePicker(type == .event ? "Date and time" : "Day", selection: $scheduledAt,
                               displayedComponents: type == .event ? [.date, .hourAndMinute] : [.date])
                }
            }
            .navigationTitle("New block").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { plannerStore.add(title: title, details: details, type: type, scheduledAt: scheduledAt); dismiss() }
                        .fontWeight(.bold).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension Date {
    static var sundayStart: Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date.now)
        let weekday = calendar.component(.weekday, from: start)
        return calendar.date(byAdding: .day, value: -(weekday - 1), to: start) ?? start
    }
}
