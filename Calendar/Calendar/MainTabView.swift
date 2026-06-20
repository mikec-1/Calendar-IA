import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = CalendarViewModel.shared
    
    var body: some View {
        TabView(selection: $viewModel.activeTab) {
            CalendarContainerView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)
                
            EventSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
                
            TasksListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(2)
            
            SettingsSwiftUIView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .environmentObject(viewModel)
    }
}
