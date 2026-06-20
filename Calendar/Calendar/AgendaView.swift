import SwiftUI
import SwiftData

struct AgendaView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var context
    
    @State private var showingAddEvent = false
    @State private var showingAddTask = false
    @State private var editingEvent: Event?
    @State private var editingTask: TodoItem?
    @State private var editingCategory: TaskCategory?
    
    var body: some View {
        ZStack {
            Theme.backgroundBase.ignoresSafeArea()
            
            let upcomingGroups = viewModel.groupedUpcomingItems(context: context)
            
            if upcomingGroups.isEmpty {
                VStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    Text("No upcoming events or tasks.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabSwipeGesture()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                        
                        // Optional Weather Header for the top of the feed
                        if let todayForecast = viewModel.todayWeather() {
                            WeatherCardView(
                                forecast: todayForecast,
                                currentTemp: viewModel.weatherData?.currentHourForecast()?.temperature,
                                isCompact: true
                            )
                            .padding(.horizontal)
                        }
                        
                        ForEach(upcomingGroups, id: \.0) { group in
                            Section(header: headerView(for: group.0)) {
                                VStack(spacing: 12) {
                                    // Events
                                    ForEach(group.1) { event in
                                        EventCardView(event: event)
                                            .id(event.id)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                viewModel.selectedDate = group.0
                                                viewModel.calendarMode = .week
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    viewModel.eventToFocusID = event.id
                                                }
                                            }
                                            .contextMenu {
                                                Button {
                                                    editingEvent = event
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        viewModel.deleteEvent(event)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                    
                                    // Tasks
                                    ForEach(group.2) { task in
                                        taskRow(for: task)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .tabSwipeGesture()
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventSheet(initialDate: viewModel.selectedDate)
                .environmentObject(viewModel)
        }
        .sheet(item: $editingEvent) { targetEvent in
            AddEventSheet(initialDate: targetEvent.date, eventToEdit: targetEvent)
                .environmentObject(viewModel)
        }
        .sheet(item: $editingTask) { task in
            AddTaskSheet(taskToEdit: task)
        }
        .sheet(item: $editingCategory) { category in
            AddCategorySheet(categoryToEdit: category)
        }
    }
    
    @ViewBuilder
    private func headerView(for date: Date) -> some View {
        HStack {
            Text(formattedDateHeader(for: date))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(Theme.backgroundBase.opacity(0.95)) // Frosted/sticky effect
    }
    
    private func formattedDateHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today,' MMM d"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow,' MMM d"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
        }
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func taskRow(for task: TodoItem) -> some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(task.categoryRef != nil ? Color(hex: task.categoryRef!.colorHex) : (task.isCompleted ? themeManager.primaryAccent : .secondary))
                .onTapGesture {
                    withAnimation {
                        viewModel.toggleTaskCompletion(task, context: context)
                    }
                }
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteTask(task, context: context)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = task
        }
    }
}
