import SwiftUI
import SwiftData

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var categoryToEdit: TaskCategory?
    
    @State private var name: String
    @State private var categoryColor: Color
    @State private var selectedIcon: String
    
    init(categoryToEdit: TaskCategory? = nil, onSave: ((TaskCategory) -> Void)? = nil) {
        self.categoryToEdit = categoryToEdit
        _name = State(initialValue: categoryToEdit?.name ?? "")
        _categoryColor = State(initialValue: categoryToEdit != nil ? Color(hex: categoryToEdit!.colorHex) : .blue)
        _selectedIcon = State(initialValue: categoryToEdit?.iconName ?? "list.bullet")
        self.onSave = onSave
    }
    
    let icons: [String] = [
        "list.bullet", "folder.fill", "bookmark.fill", "tag.fill",
        "star.fill", "heart.fill", "flag.fill", "bell.fill",
        "paperplane.fill", "briefcase.fill", "cart.fill", "house.fill",
        "graduationcap.fill", "car.fill", "airplane", "pawprint.fill",
        "doc.text.fill", "book.fill", "creditcard.fill", "gift.fill",
        "phone.fill", "envelope.fill", "map.fill", "mic.fill",
        "music.note", "camera.fill", "video.fill", "gamecontroller.fill",
        "desktopcomputer", "laptopcomputer", "iphone", "applewatch",
        "person.fill", "person.2.fill", "person.3.fill", "hand.thumbsup.fill",
        "hand.thumbsdown.fill", "brain.head.profile", "eye.fill", "mouth.fill",
        "pills.fill", "stethoscope", "bolt.fill",
        "leaf.fill", "sun.max.fill", "moon.fill", "cloud.fill",
        "drop.fill", "flame.fill", "hammer.fill", "wrench.fill",
        "screwdriver.fill", "gearshape.fill", "lightbulb.fill", "flashlight.on.fill",
        "scissors", "paintbrush.fill", "cup.and.saucer.fill", "wineglass.fill",
        "fork.knife", "bed.double.fill", "tshirt.fill", "shippingbox.fill",
        "key.fill", "lock.fill", "icloud.fill", "face.smiling.fill"
    ]
    
    var onSave: ((TaskCategory) -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Name", text: $name)
                    ColorPicker("Accent Color", selection: $categoryColor)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .foregroundColor(selectedIcon == icon ? .white : categoryColor)
                                .background(selectedIcon == icon ? categoryColor : Color.clear)
                                .clipShape(Circle())
                                .shadow(color: selectedIcon == icon ? categoryColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedIcon = icon
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if let category = categoryToEdit {
                    Section {
                        Button("Delete Category", role: .destructive) {
                            deleteCategory(category)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(categoryToEdit == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }
    
    private func saveCategory() {
        let uiColor = UIColor(categoryColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hex = String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
        
        let savedCategory: TaskCategory
        if let editingCat = categoryToEdit {
            savedCategory = viewModel.updateCategory(editingCat, name: name.trimmingCharacters(in: .whitespaces), colorHex: hex, iconName: selectedIcon, context: context)
        } else {
            let newCat = viewModel.createCategory(
                name: name.trimmingCharacters(in: .whitespaces),
                colorHex: hex,
                iconName: selectedIcon,
                context: context
            )
            // This category was explicitly created in the app
            newCat.isAppCreated = true
            savedCategory = newCat
        }
        
        try? context.save()
        
        onSave?(savedCategory)
        dismiss()
    }
    
    private func deleteCategory(_ category: TaskCategory) {
        viewModel.deleteCategory(category, context: context)
        dismiss()
    }
}
