import SwiftUI
import SwiftData

struct CategorySettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: CalendarViewModel
    
    @Query(sort: \TaskCategory.name) private var allCategories: [TaskCategory]
    
    @State private var editingCategory: TaskCategory? = nil
    @State private var showingAddCategory: Bool = false
    
    var body: some View {
        List {
            if allCategories.isEmpty {
                Text("No custom categories created yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(allCategories.sorted { 
                    if $0.isAppCreated != $1.isAppCreated { return $0.isAppCreated && !$1.isAppCreated }
                    return $0.name < $1.name
                }) { category in
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(Color(hex: category.colorHex))
                            .font(.title3)
                            .frame(width: 32)
                        
                        Text(category.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Edit") {
                            editingCategory = category
                        }
                        .foregroundColor(themeManager.primaryAccent)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteCategories)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingCategory) { cat in
            AddCategorySheet(categoryToEdit: cat)
                .environmentObject(themeManager)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet()
                .environmentObject(themeManager)
                .environmentObject(viewModel)
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let category = allCategories[index]
                // Orphaned tasks fall back to "My Tasks"
                if let mappedTasks = category.tasks {
                    for task in mappedTasks {
                        task.categoryRef = nil
                        task.category = "My Tasks"
                    }
                }

                context.delete(category)
            }
            try? context.save()
            viewModel.updateDaysInMonth()
        }
    }
}

