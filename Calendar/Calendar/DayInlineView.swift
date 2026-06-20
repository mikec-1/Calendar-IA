import SwiftUI
import SwiftData

struct DayInlineView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var context
    @Query var tasks: [TodoItem]
    
    @State private var selectedTab = 0
    @State private var editingEvent: Event?
    @State private var showingAddEvent = false
    @State private var showingAddTask = false
    @State private var expandedGroups: [String: Bool] = [:]
    @State private var editingTask: TodoItem?
    @State private var editingCategory: TaskCategory?
    
    // When embedded in WeekGridView the week strip provides the header, so hide ours
    var isEmbedded: Bool = false

    init(isEmbedded: Bool = false) {
        self.isEmbedded = isEmbedded
    }
    
    var dayEvents: [Event] {
        viewModel.events(for: viewModel.selectedDate)
    }
    
    var dayTasks: [TodoItem] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: viewModel.selectedDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let localTasks = tasks.filter { $0.date >= start && $0.date < end }
        return localTasks
    }
    
    var groupedDayTasks: [TaskGroup] {
        let dict = Dictionary(grouping: dayTasks) { task -> String in
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
        VStack(spacing: 0) {
            
            if !isEmbedded {
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundColor(themeManager.primaryAccent)
                    }
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .animation(.none, value: viewModel.selectedDate)
                        
                    Spacer()
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundColor(themeManager.primaryAccent)
                    }
                    
                    Button(action: {
                        if selectedTab == 0 {
                            showingAddEvent = true
                        } else {
                            showingAddTask = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(themeManager.primaryAccent)
                    }
                    .padding(.leading, 8)
                }
                .padding()
            }
            
            if let forecast = viewModel.selectedDateWeather() {
                VStack(spacing: 10) {
                    WeatherCardView(
                        forecast: forecast,
                        currentTemp: Calendar.current.isDateInToday(viewModel.selectedDate)
                            ? viewModel.weatherData?.currentHourForecast()?.temperature
                            : nil,
                        isCompact: false
                    )
                    
                    let hourly = viewModel.hourlyForecast(for: viewModel.selectedDate)
                    if !hourly.isEmpty {
                        HourlyWeatherTimeline(hourlyData: hourly)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Picker("View", selection: $selectedTab) {
                Text("Events").tag(0)
                Text("Tasks").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            ZStack {
                Theme.backgroundBase.ignoresSafeArea()
                
                if selectedTab == 0 {
                    HourlyTimeGrid(
                        date: viewModel.selectedDate,
                        events: dayEvents,
                        eventToFocusID: $viewModel.eventToFocusID
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            
                            if dayTasks.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color.secondary.opacity(0.3))
                                    
                                    Text("No tasks for today")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Enjoy your free time or add a new task to get started.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 60)
                                .padding(.horizontal, 40)
                            } else {
                                ForEach(groupedDayTasks) { group in
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
        // Only use tab-switch-only gesture when standalone (not embedded in WeekGridView).
        // When embedded, the parent WeekGridView applies .customHorizontalSwipe for day nav + edge tab switch.
        .gesture(
            isEmbedded ? nil : DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) * 2, abs(dx) > 50 else { return }
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    if dx < 0 {
                        // swipe left advances to the next tab
                        viewModel.navigatingForward = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if viewModel.calendarMode == .month {
                                viewModel.calendarMode = .week
                            } else if viewModel.calendarMode == .week {
                                viewModel.calendarMode = .agenda
                            }
                        }
                    } else {
                        // swipe right goes back a tab
                        viewModel.navigatingForward = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if viewModel.calendarMode == .agenda {
                                viewModel.calendarMode = .week
                            } else if viewModel.calendarMode == .week {
                                viewModel.calendarMode = .month
                            }
                        }
                    }
                }
        )
        .sheet(isPresented: $showingAddEvent) {
            AddEventSheet(initialDate: viewModel.selectedDate)
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.selectedDate)
    }
}
