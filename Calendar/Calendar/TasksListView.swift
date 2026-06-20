import SwiftUI
import SwiftData

enum TaskFilter {
    case all
    case today
    case upcoming
    case completed
}

struct TaskGroup: Identifiable {
    var id: String { name }
    let name: String
    var category: TaskCategory?
    var tasks: [TodoItem]
}

struct TasksListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: CalendarViewModel
    @Query(sort: \TodoItem.date) private var allTasks: [TodoItem]
    @Query(sort: \TaskCategory.name) private var allCategories: [TaskCategory]
    
    @State private var filter: TaskFilter = .all
    @State private var expandedGroups: [String: Bool] = [:]
    @State private var showingAddTask = false
    @State private var editingTask: TodoItem?
    @State private var editingCategory: TaskCategory?
    
    var groupedTasks: [TaskGroup] {
        // Create groups for all existing categories
        var groups: [TaskGroup] = allCategories.map { category in
            let tasksForCategory = filteredTasks.filter { $0.categoryRef?.id == category.id }
            return TaskGroup(name: category.name, category: category, tasks: tasksForCategory)
        }
        
        // Add "My Tasks" group for tasks without a category mapping
        let uncategorizedTasks = filteredTasks.filter { $0.categoryRef == nil }
        if !uncategorizedTasks.isEmpty || filter == .all {
            groups.append(TaskGroup(name: "My Tasks", category: nil, tasks: uncategorizedTasks))
        }
        
        // Filter out empty groups unless we are in the "All" view
        if filter != .all {
            groups = groups.filter { !$0.tasks.isEmpty }
        }
        
        return groups.sorted { 
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
    
    var filteredTasks: [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let combinedTasks = allTasks
        
        switch filter {
        case .all:
            return combinedTasks.filter { !$0.isCompleted }
        case .today:
            return combinedTasks.filter { !$0.isCompleted && $0.date >= today && $0.date < tomorrow }
        case .upcoming:
            return combinedTasks.filter { !$0.isCompleted && $0.date >= tomorrow && $0.hasDate }
        case .completed:
            return combinedTasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundBase.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Filter", selection: $filter) {
                        Text("All").tag(TaskFilter.all)
                        Text("Today").tag(TaskFilter.today)
                        Text("Upcoming").tag(TaskFilter.upcoming)
                        Text("Completed").tag(TaskFilter.completed)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if (filter != .all && filteredTasks.isEmpty) || (filter == .all && groupedTasks.isEmpty) {
                        Spacer()
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                            .padding()
                        Text("No tasks found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        List {
                            if filter == .all || filter == .completed {
                                ForEach(groupedTasks) { group in
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { expandedGroups[group.name] ?? true }, // Default expanded
                                            set: { expandedGroups[group.name] = $0 }
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
                                            
                                            Spacer()
                                            
                                            Text("\(group.tasks.count)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.trailing, 4)
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
                            } else {
                                ForEach(filteredTasks) { task in
                                    taskRow(for: task)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(themeManager.primaryAccent)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet()
            }
            .sheet(item: $editingTask) { task in
                AddTaskSheet(taskToEdit: task)
            }
            .sheet(item: $editingCategory) { category in
                AddCategorySheet(categoryToEdit: category)
            }
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                
                if task.hasDate {
                    Text(formattedDate(task.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(task.isCompleted ? 0.5 : 1.0)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = task
        }
        .swipeActions {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteTask(task, context: context)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    

    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
