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
                    weekProgress
                    ConsistencyGrid(weekStart: weekStart)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button(plannerStore.isSaving ? "Saving…" : "Done") { saveAndClose() }
                        .disabled(plannerStore.isSaving)
                }
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
            .overlay(alignment: .bottom) {
                if let streak = plannerStore.streakCelebration {
                    StreakCelebrationBar(streak: streak)
                        .padding(.horizontal, 24).padding(.bottom, 22)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.82), value: plannerStore.streakCelebration)
        }
    }

    private func saveAndClose() {
        Task {
            _ = await plannerStore.saveWeek(starting: weekStart)
            dismiss()
        }
    }

    private var weekProgress: some View {
        let items = plannerStore.trackableItems(inWeekStarting: weekStart)
        let complete = items.filter(\.isComplete).count
        let progress = plannerStore.progress(inWeekStarting: weekStart)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("WEEKLY PROGRESS").font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(AppTheme.success)
                    Text(items.isEmpty ? "Plan your first routine" : "\(complete) of \(items.count) scheduled items complete")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.success)
            }
            ProgressView(value: progress)
                .tint(AppTheme.success).scaleEffect(x: 1, y: 1.7, anchor: .center)
        }
        .padding(18).background(CardBackground(radius: 20))
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
                if !pendingEntries.isEmpty {
                    plannerSectionTitle("TO DO", count: pendingEntries.count, color: AppTheme.blue)
                    ForEach(pendingEntries) { entry in PlannerBlockView(entry: entry) }
                }
                if !completedEntries.isEmpty {
                    plannerSectionTitle("COMPLETED", count: completedEntries.count, color: AppTheme.success)
                    ForEach(completedEntries) { entry in PlannerBlockView(entry: entry) }
                }
                if !noteEntries.isEmpty {
                    plannerSectionTitle("NOTES", count: noteEntries.count, color: .orange)
                    ForEach(noteEntries) { entry in PlannerBlockView(entry: entry) }
                }
            }
        }
    }

    private func plannerSectionTitle(_ title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 7) {
            Text(title).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(color)
            Text("\(count)").font(.system(size: 10, weight: .bold)).foregroundStyle(AppTheme.mutedText)
            Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5)
        }.padding(.top, 4)
    }

    private var dayEntries: [PlannerEntry] { plannerStore.entries(on: selectedDay) }
    private var pendingEntries: [PlannerEntry] { dayEntries.filter { $0.entryType != .note && !$0.isComplete } }
    private var completedEntries: [PlannerEntry] { dayEntries.filter { $0.entryType != .note && $0.isComplete } }
    private var noteEntries: [PlannerEntry] { dayEntries.filter { $0.entryType == .note } }
    private var weekDays: [Date] { (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) } }
    private var weekRange: String {
        guard let end = weekDays.last else { return "" }
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }
    private var daySubtitle: String {
        let items = dayEntries.filter { $0.entryType != .note }
        let complete = items.filter(\.isComplete).count
        return items.isEmpty ? selectedDay.formatted(.dateTime.month(.wide).day()) : "\(complete) of \(items.count) scheduled items complete"
    }
    private func isSelected(_ day: Date) -> Bool { Calendar.current.isDate(day, inSameDayAs: selectedDay) }
    private func moveWeek(_ offset: Int) {
        if let date = Calendar.current.date(byAdding: .day, value: offset * 7, to: weekStart) { weekStart = date; selectedDay = date }
    }
}

struct ConsistencyGrid: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    let weekStart: Date

    private let dayColumnWidth: CGFloat = 72
    private let habitColumnWidth: CGFloat = 46

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Consistency grid", systemImage: "square.grid.3x3.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Tap a square only after you finish")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                Text("\(completedCount)/\(scheduledCount)")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.indigo)
                    .padding(.horizontal, 10).padding(.vertical, 6).background(AppTheme.softBlue, in: Capsule())
            }

            if habitTitles.isEmpty {
                Label("Add a multi-day activity to start tracking consistency.", systemImage: "calendar.badge.plus")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        gridHeader
                        ForEach(weekDays, id: \.self) { day in gridRow(day) }
                    }
                }
            }
        }
        .padding(18).background(CardBackground(radius: 22))
    }

    private var gridHeader: some View {
        HStack(spacing: 0) {
            Text("DAY").frame(width: dayColumnWidth, alignment: .leading)
            ForEach(habitTitles, id: \.self) { title in
                Image(systemName: symbol(for: title))
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.indigo)
                    .frame(width: habitColumnWidth)
                    .accessibilityLabel(title)
            }
            Text("PROGRESS").frame(width: 110, alignment: .leading)
            Text("NOTES").frame(width: 140, alignment: .leading)
        }
        .font(.system(size: 9, weight: .bold)).tracking(0.8).foregroundStyle(AppTheme.mutedText)
        .padding(.vertical, 10)
    }

    private func gridRow(_ day: Date) -> some View {
        let activities = plannerStore.entries(on: day).filter { $0.entryType == .activity }
        let completed = activities.filter(\.isComplete).count
        let progress = activities.isEmpty ? 0 : Double(completed) / Double(activities.count)
        let note = plannerStore.entries(on: day).first { $0.entryType == .note }?.title
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.system(size: 11, weight: .bold))
                Text(day.formatted(.dateTime.day())).font(.system(size: 10, weight: .medium)).foregroundStyle(AppTheme.mutedText)
            }.frame(width: dayColumnWidth, alignment: .leading)

            ForEach(habitTitles, id: \.self) { title in
                if let entry = activities.first(where: { $0.title == title }) {
                    Button { plannerStore.toggle(entry) } label: {
                        Image(systemName: entry.isComplete ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(entry.isComplete ? AppTheme.success : AppTheme.rail)
                            .frame(width: habitColumnWidth, height: 38)
                    }.buttonStyle(.plain).accessibilityLabel("\(title), \(entry.isComplete ? "completed" : "not completed")")
                } else {
                    Image(systemName: "minus").font(.system(size: 10, weight: .bold)).foregroundStyle(AppTheme.rail.opacity(0.55))
                        .frame(width: habitColumnWidth, height: 38)
                }
            }

            HStack(spacing: 7) {
                Text("\(Int(progress * 100))%").font(.system(size: 10, weight: .bold)).frame(width: 30, alignment: .trailing)
                ProgressView(value: progress).tint(progress == 1 ? AppTheme.success : AppTheme.indigo).frame(width: 64)
            }.frame(width: 110, alignment: .leading)
            Text(note ?? "—").font(.system(size: 11, weight: .medium)).foregroundStyle(note == nil ? AppTheme.rail : AppTheme.mutedText)
                .lineLimit(1).frame(width: 140, alignment: .leading)
        }
        .frame(height: 45)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.cardBorder).frame(height: 0.5) }
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }
    private var habitTitles: [String] {
        var seen = Set<String>()
        return weekDays.flatMap { plannerStore.entries(on: $0) }
            .filter { $0.entryType == .activity }
            .map(\.title).filter { seen.insert($0).inserted }
    }
    private var scheduledCount: Int { weekDays.flatMap { plannerStore.entries(on: $0) }.filter { $0.entryType == .activity }.count }
    private var completedCount: Int { weekDays.flatMap { plannerStore.entries(on: $0) }.filter { $0.entryType == .activity && $0.isComplete }.count }
    private func symbol(for title: String) -> String {
        let symbols = ["checklist", "book.fill", "target", "sparkles", "brain.head.profile", "calendar.badge.checkmark"]
        return symbols[Int(UInt(bitPattern: title.hashValue) % UInt(symbols.count))]
    }
}

struct StreakCelebrationBar: View {
    let streak: Int
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill").font(.system(size: 20, weight: .bold)).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity completed").font(.system(size: 14, weight: .bold))
                Text(streak == 1 ? "Great start — keep your momentum." : "Your consistency streak is now \(streak) days.")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill").foregroundStyle(AppTheme.success)
        }
        .padding(.horizontal, 16).frame(height: 66)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppTheme.cardBorder, lineWidth: 0.7) }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
    }
}

struct PlannerBlockView: View {
    @EnvironmentObject private var plannerStore: PlannerStore
    let entry: PlannerEntry
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button { if entry.entryType != .note { plannerStore.toggle(entry) } } label: {
                Image(systemName: entry.entryType != .note && entry.isComplete ? "checkmark.circle.fill" : entry.entryType.iconName)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(blockColor).frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(entry.entryType == .note)
            .accessibilityLabel(entry.isComplete ? "Mark \(entry.title) incomplete" : "Mark \(entry.title) complete")
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
    @State private var selectedWeekdays: Set<Int> = []

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
                if type == .activity {
                    Section("Repeat this activity") {
                        Text("Choose multiple days to build a consistent weekly routine.")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 7) {
                            ForEach(1...7, id: \.self) { weekday in
                                Button {
                                    if selectedWeekdays.contains(weekday) { selectedWeekdays.remove(weekday) }
                                    else { selectedWeekdays.insert(weekday) }
                                } label: {
                                    Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : AppTheme.blue)
                                        .frame(maxWidth: .infinity).frame(height: 36)
                                        .background(selectedWeekdays.contains(weekday) ? AppTheme.blue : AppTheme.softBlue, in: Circle())
                                }.buttonStyle(.plain)
                            }
                        }
                        Button(selectedWeekdays.count == 7 ? "Clear all days" : "Select entire week") {
                            selectedWeekdays = selectedWeekdays.count == 7 ? [] : Set(1...7)
                        }
                        .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .navigationTitle("New block").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save(); dismiss() }
                        .fontWeight(.bold).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard type == .activity, !selectedWeekdays.isEmpty else {
            plannerStore.add(title: title, details: details, type: type, scheduledAt: scheduledAt)
            return
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: scheduledAt)
        let sunday = calendar.date(byAdding: .day, value: -(calendar.component(.weekday, from: start) - 1), to: start) ?? start
        let time = calendar.dateComponents([.hour, .minute], from: scheduledAt)
        let dates = selectedWeekdays.sorted().compactMap { weekday -> Date? in
            guard let day = calendar.date(byAdding: .day, value: weekday - 1, to: sunday) else { return nil }
            return calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: day)
        }
        plannerStore.add(title: title, details: details, type: type, dates: dates)
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
