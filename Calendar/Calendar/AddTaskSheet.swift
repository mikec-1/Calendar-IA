import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: CalendarViewModel
    
    // Existing categories fetching for the dynamic Picker
    @Query(sort: \TaskCategory.name) private var allCategories: [TaskCategory]
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: Int = 0 // 0: None, 1: Low, 2: Medium, 3: High
    @State private var hasTime: Bool = false
    @State private var hasDate: Bool = true
    @State private var date: Date = Date()
    @State private var isCompleted: Bool = false
    
    var taskToEdit: TodoItem?
    var initialDate: Date
    
    init(initialDate: Date = Date(), taskToEdit: TodoItem? = nil) {
        self.initialDate = initialDate
        self.taskToEdit = taskToEdit
        _title = State(initialValue: taskToEdit?.title ?? "")
        _notes = State(initialValue: taskToEdit?.notes ?? "")
        _priority = State(initialValue: taskToEdit?.priority ?? 0)
        _hasTime = State(initialValue: taskToEdit?.hasTime ?? false)
        _hasDate = State(initialValue: taskToEdit?.hasDate ?? true)
        let savedDate = taskToEdit?.date ?? initialDate
        let resolvedDate = (savedDate == Date.distantFuture || !(taskToEdit?.hasDate ?? true)) ? initialDate : savedDate
        _date = State(initialValue: resolvedDate)
        _isCompleted = State(initialValue: taskToEdit?.isCompleted ?? false)
        _selectedCategory = State(initialValue: taskToEdit?.categoryRef)
    }

    @State private var selectedCategory: TaskCategory?
    @State private var showingAddCategory: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    TextField("Notes (optional)", text: $notes)
                    
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(0)
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    
                    Toggle("Has Due Date", isOn: $hasDate)
                        .onChange(of: hasDate) { newValue in
                            if !newValue {
                                hasTime = false
                            }
                        }
                    
                    if hasDate {
                        Toggle("Include Time", isOn: $hasTime)
                        
                        if hasTime {
                            DatePicker("Due Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        } else {
                            DatePicker("Due Date", selection: $date, displayedComponents: [.date])
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategory) {
                        Text("My Tasks (No Apple Sync)").tag(TaskCategory?.none)
                        ForEach(allCategories.sorted { 
                            if $0.isAppCreated != $1.isAppCreated { return $0.isAppCreated && !$1.isAppCreated }
                            return $0.name < $1.name
                        }) { cat in
                            Text(cat.name).tag(cat as TaskCategory?)
                        }
                    }
                    
                    Button("+ Create New Category") {
                        showingAddCategory = true
                    }
                    .foregroundColor(themeManager.primaryAccent)
                }
                
                Section {
                    Toggle("Mark as Completed", isOn: $isCompleted)
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .bold()
                }
            }
            .onAppear {
                if taskToEdit == nil {
                    date = initialDate
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(categoryToEdit: nil) { newCat in
                    selectedCategory = newCat
                }
                .environmentObject(themeManager)
                .environmentObject(viewModel)
            }
        }
    }
    
    private func saveTask() {
        if let editing = taskToEdit {
            viewModel.updateTodoItem(
                task: editing,
                title: title.trimmingCharacters(in: .whitespaces),
                date: hasDate ? date : Date.distantFuture,
                hasTime: hasTime,
                hasDate: hasDate,
                isCompleted: isCompleted,
                category: selectedCategory,
                context: context
            )
        } else {
            viewModel.addTodoItem(
                title: title.trimmingCharacters(in: .whitespaces),
                date: hasDate ? date : Date.distantFuture,
                hasTime: hasTime,
                hasDate: hasDate,
                isCompleted: isCompleted,
                category: selectedCategory,
                context: context
            )
        }
        
        dismiss()
    }
}
