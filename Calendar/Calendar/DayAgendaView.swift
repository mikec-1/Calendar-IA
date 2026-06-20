import SwiftUI
import SwiftData

struct DayAgendaView: View {
    let day: CalendarDay
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var context
    
    @Query var queriedTasks: [TodoItem]
    
    var localTasks: [TodoItem] {
        let start = Calendar.current.startOfDay(for: day.date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return queriedTasks.filter { $0.date >= start && $0.date < end }
    }
    
    var allTasksForDay: [TodoItem] {
        return localTasks
    }
    
    @State private var showingAddEvent = false
    @State private var showingAddTask = false
    @State private var editingEvent: Event?
    @State private var editingTask: TodoItem?
    @State private var editingCategory: TaskCategory?
    @State private var expandedGroups: [String: Bool] = [:]
    
    @State private var selectedTab = 0
    
    init(day: CalendarDay) {
        self.day = day
    }
    
    var events: [Event] {
        viewModel.events(for: day.date)
    }
    
    var groupedTasks: [TaskGroup] {
        let dict = Dictionary(grouping: allTasksForDay) { task -> String in
            return task.categoryRef?.name ?? task.category ?? "My Tasks"
        }
        return dict.map { (key, value) in
            let cat = value.first?.categoryRef
            return TaskGroup(name: key, category: cat, tasks: value)
        }
        .sorted { 
            if $0.name == "My Tasks" { return true }
            if $1.name == "My Tasks" { return false }
            
            let isAppCreated0 = $0.category?.isAppCreated ?? false
            let isAppCreated1 = $1.category?.isAppCreated ?? false
            
            if isAppCreated0 != isAppCreated1 {
                return isAppCreated0 && !isAppCreated1
            }
            
            return $0.name < $1.name 
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let forecast = viewModel.weatherData?.dailyForecast(for: day.date) {
                    VStack(spacing: 10) {
                        WeatherCardView(
                            forecast: forecast,
                            currentTemp: Calendar.current.isDateInToday(day.date)
                                ? viewModel.weatherData?.currentHourForecast()?.temperature
                                : nil,
                            isCompact: false
                        )
                        
                        let hourly = viewModel.hourlyForecast(for: day.date)
                        if !hourly.isEmpty {
                            HourlyWeatherTimeline(hourlyData: hourly)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Picker("View", selection: $selectedTab) {
                    Text("Events").tag(0)
                    Text("Tasks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Theme.backgroundBase)
                
                ZStack {
                    Theme.backgroundBase.ignoresSafeArea()
                    
                    if selectedTab == 0 {
                        if events.isEmpty {
                            VStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                    .padding()
                                Text("No events for this day.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(events) { event in
                                        EventCardView(event: event)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                editingEvent = event
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
                                }
                                .padding()
                            }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {

                                if allTasksForDay.isEmpty {
                                    Text("No tasks for today! 🎉")
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    ForEach(groupedTasks) { group in
                                        DisclosureGroup(
                                            isExpanded: Binding(
                                                get: { expandedGroups[group.id] ?? true },
                                                set: { expandedGroups[group.id] = $0 }
                                            )
                                        ) {
                                            ForEach(group.tasks) { task in
                                                taskRow(for: task)
                                            }
                                        } label: {
                                            HStack {
                                                if let cat = group.category {
                                                    Image(systemName: cat.iconName)
                                                        .foregroundColor(Color(hex: cat.colorHex))
                                                }
                                                Text(group.name)
                                                    .font(.headline)
                                                    .foregroundColor(group.category != nil ? Color(hex: group.category!.colorHex) : .primary)
                                            }
                                            .padding(.vertical, 4)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                if let cat = group.category {
                                                    editingCategory = cat
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    if selectedTab == 0 {
                        showingAddEvent = true
                    } else {
                        showingAddTask = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            )
            .sheet(isPresented: $showingAddEvent) {
                AddEventSheet(initialDate: day.date)
                    .environmentObject(viewModel)
            }
            .sheet(item: $editingEvent) { targetEvent in
                AddEventSheet(initialDate: targetEvent.date, eventToEdit: targetEvent)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(initialDate: viewModel.selectedDate)
            }
            .sheet(item: $editingTask) { task in
                AddTaskSheet(taskToEdit: task)
            }
            .sheet(item: $editingCategory) { category in
                AddCategorySheet(categoryToEdit: category)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: day.date)
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

struct EventCardView: View {
    let event: Event
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(themeManager.primaryAccent)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.subheadline)
                    Text(timeString(for: event))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                if let location = event.locationName {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline)
                        Text(location)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func timeString(for event: Event) -> String {
        if event.isAllDay {
            return "All-Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.date)) - \(formatter.string(from: event.endDate))"
    }
}
