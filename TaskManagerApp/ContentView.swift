import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .overview
    @State private var showingNewTask = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .overview:
                    DashboardView()
                case .tasks:
                    TaskListView()
                case .stats:
                    AnalysisView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AppTabBar(selectedTab: $selectedTab, showingAddTask: $showingNewTask)
        }
        .sheet(isPresented: $showingNewTask) {
            AddTaskView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .tint(AppTheme.blue)
    }
}

#Preview {
    ContentView()
}
