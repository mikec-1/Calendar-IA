import Foundation
import SwiftData

/// Represents a single user event on the calendar
@Model
class Event: Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var endDate: Date = Date()
    var isAllDay: Bool = false
    var locationName: String?
    var notes: String?
    var isReminderSet: Bool = false
    var appleCalendarEventIdentifier: String?
    
    init(id: UUID = UUID(), name: String, date: Date, endDate: Date? = nil, isAllDay: Bool = false, locationName: String? = nil, notes: String? = nil, isReminderSet: Bool = false, appleCalendarEventIdentifier: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.endDate = endDate ?? date.addingTimeInterval(3600)
        self.isAllDay = isAllDay
        self.locationName = locationName
        self.notes = notes
        self.isReminderSet = isReminderSet
        self.appleCalendarEventIdentifier = appleCalendarEventIdentifier
    }
}
