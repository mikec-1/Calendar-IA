import Foundation
import SwiftData

@Model
class TodoItem: Identifiable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date
    var category: String?
    var notes: String?
    var priority: Int // 0: None, 1: Low, 2: Medium, 3: High
    var hasTime: Bool = false
    var hasDate: Bool = true
    var appleReminderIdentifier: String?
    
    var categoryRef: TaskCategory?
    
    init(id: UUID = UUID(), title: String, date: Date, isCompleted: Bool = false, notes: String? = nil, priority: Int = 0, category: String? = nil, hasTime: Bool = false, hasDate: Bool = true, appleReminderIdentifier: String? = nil, categoryRef: TaskCategory? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.notes = notes
        self.priority = priority
        self.category = category
        self.hasTime = hasTime
        self.hasDate = hasDate
        self.appleReminderIdentifier = appleReminderIdentifier
        self.categoryRef = categoryRef
    }
}
