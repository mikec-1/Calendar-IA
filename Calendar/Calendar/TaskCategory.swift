import Foundation
import SwiftData

@Model
class TaskCategory: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var appleReminderListIdentifier: String?
    var isAppCreated: Bool
    
    @Relationship(inverse: \TodoItem.categoryRef)
    var tasks: [TodoItem]?
    
    init(id: UUID = UUID(), name: String, colorHex: String = "#FFCC00", iconName: String = "folder.fill", appleReminderListIdentifier: String? = nil, isAppCreated: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.appleReminderListIdentifier = appleReminderListIdentifier
        self.isAppCreated = isAppCreated
    }
}
