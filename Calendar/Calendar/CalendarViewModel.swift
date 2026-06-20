import Foundation
import SwiftData
import EventKit
import CoreLocation
import UIKit
import SwiftUI

enum CalendarMode {
    case month
    case week
    case agenda
}

/// The ViewModel responsible for managing the state and logic of the Calendar view.
class CalendarViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// Shared instance used throughout the app.
    static let shared = CalendarViewModel()
    
    /// The currently selected/viewed date in the calendar. Defaults to today.
    @Published var selectedDate: Date = Date()
    
    /// The array of days to display in the current month's grid.
    @Published var totalSquares: [CalendarDay] = []
    
    /// Global navigation state
    @Published var activeTab: Int = 0
    @Published var calendarMode: CalendarMode = .month
    @Published var eventToFocusID: UUID?
    @Published var weatherData: WeatherData?
    
    /// Tracks the direction of the last navigation for slide animations
    /// true = forward (slide left), false = backward (slide right)
    @Published var navigatingForward: Bool = true
    
    /// Counter that changes whenever we navigate months/weeks, forcing SwiftUI to create a new view identity
    @Published var navigationID: Int = 0
    
    @Published private(set) var events: [Event] = []
    var modelContext: ModelContext? {
        didSet {
            loadEvents()
        }
    }
    
    // Suppress incoming EventKit changes when we are pushing outbound saves
    private var isSyncSuppressed = false
    
    /// A helper object for date math.
    private let calendarHelper = CalendarHelper()
    
    private let eventStore = EKEventStore()
    
    // MARK: - Event Management
    
    private init() {
        requestCalendarAccess()
        
        NotificationCenter.default.addObserver(self, selector: #selector(eventStoreChanged), name: .EKEventStoreChanged, object: eventStore)
    }
    
    @objc private func eventStoreChanged() {
        guard !isSyncSuppressed else { return }
        if UserDefaults.standard.object(forKey: "useAppleReminders") as? Bool ?? true,
           EKEventStore.authorizationStatus(for: .reminder) == .authorized {
            syncAppleReminders()
        }
        
        let useAppleCalendar = UserDefaults.standard.object(forKey: "useAppleCalendar") as? Bool ?? true
        if #available(iOS 17.0, *) {
            if useAppleCalendar && EKEventStore.authorizationStatus(for: .event) == .fullAccess {
                syncAppleCalendars()
            }
        } else {
            if useAppleCalendar && EKEventStore.authorizationStatus(for: .event) == .authorized {
                syncAppleCalendars()
            }
        }
    }
    
    private func requestCalendarAccess() {
        Task {
            do {
                if #available(iOS 17.0, *) {
                    let eventAccess = try await eventStore.requestFullAccessToEvents()
                    let reminderAccess = try await eventStore.requestFullAccessToReminders()
                    print("Event access: \(eventAccess), Reminder access: \(reminderAccess)")
                    
                    if eventAccess || reminderAccess {
                        DispatchQueue.main.async {
                            self.updateDaysInMonth()
                        }
                    }
                } else {
                    // Fallback on earlier versions
                    eventStore.requestAccess(to: .event) { (granted, _) in
                        if granted { print("Event access granted") }
                    }
                    eventStore.requestAccess(to: .reminder) { (granted, _) in
                        if granted { print("Reminder access granted") }
                    }
                }
            } catch {
                print("Failed to request Apple permissions: \(error)")
            }
        }
    }
    
    func addEvent(_ event: Event) {
        // Push to Apple Calendar if enabled
        if UserDefaults.standard.object(forKey: "useAppleCalendar") as? Bool ?? true {
            if #available(iOS 17.0, *) {
                if EKEventStore.authorizationStatus(for: .event) == .fullAccess || EKEventStore.authorizationStatus(for: .event) == .writeOnly {
                    pushNewEventToAppleCalendar(event)
                }
            } else {
                if EKEventStore.authorizationStatus(for: .event) == .authorized {
                    pushNewEventToAppleCalendar(event)
                }
            }
        }
        
        modelContext?.insert(event)
        events.append(event)
        try? modelContext?.save()
        updateDaysInMonth()
    }
    
    private func pushNewEventToAppleCalendar(_ event: Event) {
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.name
            ekEvent.startDate = event.date
            ekEvent.endDate = event.endDate
            ekEvent.isAllDay = event.isAllDay
            ekEvent.location = event.locationName
            ekEvent.calendar = defaultCalendar
            
            self.isSyncSuppressed = true
            do {
                try eventStore.save(ekEvent, span: .thisEvent, commit: true)
                event.appleCalendarEventIdentifier = ekEvent.eventIdentifier
            } catch {
                print("Failed to save to Apple Calendar: \(error)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isSyncSuppressed = false
                self.syncAppleCalendars()
            }
        }
    }
    
    func updateEvent(_ event: Event, name: String, date: Date, endDate: Date, isAllDay: Bool, locationName: String?, context: ModelContext) {
        event.name = name
        event.date = date
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.locationName = locationName
        
        let useAppleCalendar = UserDefaults.standard.object(forKey: "useAppleCalendar") as? Bool ?? true
        if useAppleCalendar, let id = event.appleCalendarEventIdentifier {
            if let ekEvent = eventStore.event(withIdentifier: id) {
                ekEvent.title = name
                ekEvent.startDate = date
                ekEvent.endDate = endDate
                ekEvent.isAllDay = isAllDay
                ekEvent.location = locationName
                
                self.isSyncSuppressed = true
                do {
                    try eventStore.save(ekEvent, span: .thisEvent, commit: true)
                } catch {
                    print("Failed to update Apple Calendar: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleCalendars()
                }
            }
        }
        
        try? context.save()
        updateDaysInMonth()
    }
    
    /// Moves an event to a new time, preserving duration unless newEndDate is specified.
    /// Used by drag-and-drop on the timeline.
    func moveEvent(_ event: Event, to newStart: Date, newEndDate: Date? = nil) {
        let duration = event.endDate.timeIntervalSince(event.date)
        event.date = newStart
        event.endDate = newEndDate ?? newStart.addingTimeInterval(duration)
        
        let useAppleCalendar = UserDefaults.standard.object(forKey: "useAppleCalendar") as? Bool ?? true
        if useAppleCalendar, let id = event.appleCalendarEventIdentifier {
            if let ekEvent = eventStore.event(withIdentifier: id) {
                ekEvent.startDate = event.date
                ekEvent.endDate = event.endDate
                
                self.isSyncSuppressed = true
                do {
                    try eventStore.save(ekEvent, span: .thisEvent, commit: true)
                } catch {
                    print("Failed to update Apple Calendar on drag: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleCalendars()
                }
            }
        }
        
        try? modelContext?.save()
        updateDaysInMonth()
    }
    
    func deleteEvent(_ event: Event) {
        // Delete from Apple Calendar if applicable
        if let eventId = event.appleCalendarEventIdentifier {
            if let ekEvent = eventStore.event(withIdentifier: eventId) {
                self.isSyncSuppressed = true
                do {
                    try eventStore.remove(ekEvent, span: .thisEvent, commit: true)
                } catch {
                    print("Failed to delete from Apple Calendar: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleCalendars()
                }
            }
        }
        
        modelContext?.delete(event)
        events.removeAll { $0.id == event.id }
        try? modelContext?.save()
        updateDaysInMonth()
    }
    
    func deleteTask(_ task: TodoItem, context: ModelContext) {
        if let reminderId = task.appleReminderIdentifier {
            fetchEKReminder(withIdentifier: reminderId) { [weak self] ekReminder in
                guard let self = self, let ekReminder = ekReminder else { return }
                self.isSyncSuppressed = true
                do {
                    try self.eventStore.remove(ekReminder, commit: true)
                } catch {
                    print("Failed to delete from Apple Reminders: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleReminders()
                }
            }
        }
        
        context.delete(task)
        try? context.save()
        updateDaysInMonth()
    }
    
    func toggleTaskCompletion(_ task: TodoItem, context: ModelContext) {
        task.isCompleted.toggle()
        
        if let reminderId = task.appleReminderIdentifier {
            fetchEKReminder(withIdentifier: reminderId) { [weak self] ekReminder in
                guard let self = self, let ekReminder = ekReminder else { return }
                ekReminder.isCompleted = task.isCompleted
                self.isSyncSuppressed = true
                do {
                    try self.eventStore.save(ekReminder, commit: true)
                } catch {
                    print("Failed to update Apple Reminder completion: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleReminders()
                }
            }
        }
        
        try? context.save()
        updateDaysInMonth()
    }
    
    func addTodoItem(title: String, date: Date, hasTime: Bool, hasDate: Bool, isCompleted: Bool, category: TaskCategory?, context: ModelContext) {
        var appleIdentifier: String? = nil
        
        // Push to Apple Reminders if applicable
        let useAppleReminders = UserDefaults.standard.object(forKey: "useAppleReminders") as? Bool ?? true
        if useAppleReminders, EKEventStore.authorizationStatus(for: .reminder) == .authorized {
            
            var targetCalendar: EKCalendar? = nil
            if let cat = category, let listId = cat.appleReminderListIdentifier {
                targetCalendar = eventStore.calendar(withIdentifier: listId)
            } else {
                targetCalendar = eventStore.defaultCalendarForNewReminders()
            }
            
            if let ekCalendar = targetCalendar {
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = title
                reminder.calendar = ekCalendar
                reminder.isCompleted = isCompleted
                
                if hasDate {
                    if hasTime && date != Date.distantFuture {
                        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                        reminder.dueDateComponents = components
                    } else if !hasTime && date != Date.distantFuture {
                        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        reminder.dueDateComponents = components
                    }
                } else {
                    reminder.dueDateComponents = nil
                }
                
                self.isSyncSuppressed = true
                do {
                    try self.eventStore.save(reminder, commit: true)
                    appleIdentifier = reminder.calendarItemIdentifier
                } catch {
                    print("Failed to save to Apple Reminders: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleReminders()
                }
            }
        }
        
        let newTask = TodoItem(
            title: title,
            date: date,
            isCompleted: isCompleted,
            category: category?.name,
            hasTime: hasTime,
            hasDate: hasDate,
            appleReminderIdentifier: appleIdentifier,
            categoryRef: category
        )
        context.insert(newTask)
        try? context.save()
        updateDaysInMonth()
    }
    
    func updateTodoItem(task: TodoItem, title: String, date: Date, hasTime: Bool, hasDate: Bool, isCompleted: Bool, category: TaskCategory?, context: ModelContext) {
        task.title = title
        task.date = date
        task.hasTime = hasTime
        task.hasDate = hasDate
        task.isCompleted = isCompleted
        task.category = category?.name
        task.categoryRef = category
        
        let useAppleReminders = UserDefaults.standard.object(forKey: "useAppleReminders") as? Bool ?? true
        if useAppleReminders, EKEventStore.authorizationStatus(for: .reminder) == .authorized,
           let id = task.appleReminderIdentifier {
           
            fetchEKReminder(withIdentifier: id) { [weak self] ekReminder in
                guard let self = self, let reminder = ekReminder else { return }
                
                reminder.title = title
                reminder.isCompleted = isCompleted
               
                if let cat = category, let listId = cat.appleReminderListIdentifier, let ekCalendar = self.eventStore.calendar(withIdentifier: listId) {
                    reminder.calendar = ekCalendar
                } else if category == nil, let defaultCal = self.eventStore.defaultCalendarForNewReminders() {
                    reminder.calendar = defaultCal
                }
               
                if hasDate {
                    if hasTime && date != Date.distantFuture {
                        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                        reminder.dueDateComponents = components
                    } else if !hasTime && date != Date.distantFuture {
                        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        reminder.dueDateComponents = components
                    }
                } else {
                    reminder.dueDateComponents = nil
                }
               
                self.isSyncSuppressed = true
                do {
                    try self.eventStore.save(reminder, commit: true)
                } catch {
                    print("Failed to update Apple Reminders: \(error)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSyncSuppressed = false
                    self.syncAppleReminders()
                }
            }
        }
        
        try? context.save()
        updateDaysInMonth()
    }
    
    func createCategory(name: String, colorHex: String, iconName: String, context: ModelContext) -> TaskCategory {
        var appleListId: String? = nil
        
        if UserDefaults.standard.object(forKey: "useAppleReminders") as? Bool ?? true,
           EKEventStore.authorizationStatus(for: .reminder) == .authorized {
            
            if let defaultSource = eventStore.defaultCalendarForNewReminders()?.source {
                let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
                newCalendar.title = name
                newCalendar.source = defaultSource
                
                do {
                    try eventStore.saveCalendar(newCalendar, commit: true)
                    appleListId = newCalendar.calendarIdentifier
                } catch {
                    print("Failed to create EKCalendar: \(error)")
                }
            }
        }
        
        let newCat = TaskCategory(name: name, colorHex: colorHex, iconName: iconName, appleReminderListIdentifier: appleListId)
        context.insert(newCat)
        try? context.save()
        return newCat
    }
    
    func updateCategory(_ category: TaskCategory, name: String, colorHex: String, iconName: String, context: ModelContext) -> TaskCategory {
        category.name = name
        category.colorHex = colorHex
        category.iconName = iconName
        
        try? context.save()
        
        if let listId = category.appleReminderListIdentifier,
           let ekCal = eventStore.calendar(withIdentifier: listId) as? EKCalendar {
            ekCal.title = name
            
            let uiColor = UIColor(Color(hex: colorHex))
            ekCal.cgColor = uiColor.cgColor
            
            // Push icon change back to Apple Reminders (KVC) - safely!
            if ekCal.responds(to: NSSelectorFromString("setSymbolName:")) {
                ekCal.setValue(iconName, forKey: "symbolName")
            }
            if ekCal.responds(to: NSSelectorFromString("setSymbolIdentifier:")) {
                ekCal.setValue(iconName, forKey: "symbolIdentifier")
            }
            
            do {
                try eventStore.saveCalendar(ekCal, commit: true)
            } catch {
                print("Failed to update EKCalendar color/title/icon: \(error)")
            }
        }
        
        return category
    }
    
    func deleteCategory(_ category: TaskCategory, context: ModelContext) {
        if let listId = category.appleReminderListIdentifier,
           let ekCal = eventStore.calendar(withIdentifier: listId) {
            do {
                try eventStore.removeCalendar(ekCal, commit: true)
            } catch {
                print("Failed to delete EKCalendar: \(error)")
            }
        }
        context.delete(category)
        try? context.save()
    }
    
    private func syncAppleReminders() {
        guard !isSyncSuppressed else { return }
        guard let context = modelContext else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 1. Sync Categories (Lists) First - ensures empty lists are imported
            let ekCalendars = self.eventStore.calendars(for: .reminder)
            let currentCategories = (try? context.fetch(FetchDescriptor<TaskCategory>())) ?? []
            var dynamicCategories = currentCategories
            
            for ekCal in ekCalendars {
                let uiColor = UIColor(cgColor: ekCal.cgColor)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let hex = String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
                
                // EKCalendar exposes its symbol under different keys across iOS versions
                var ekSymbol: String? = nil
                if ekCal.responds(to: NSSelectorFromString("symbolName")) {
                    ekSymbol = ekCal.value(forKey: "symbolName") as? String
                }
                if ekSymbol == nil && ekCal.responds(to: NSSelectorFromString("symbolIdentifier")) {
                    ekSymbol = ekCal.value(forKey: "symbolIdentifier") as? String
                }
                if ekSymbol == nil && ekCal.responds(to: NSSelectorFromString("symbol")) {
                    ekSymbol = ekCal.value(forKey: "symbol") as? String
                }     
                
                // Fallback mapping based on common list names if no symbol found
                if ekSymbol == nil {
                    let name = ekCal.title.lowercased()
                    if name.contains("work") { ekSymbol = "briefcase.fill" }
                    else if name.contains("home") || name.contains("house") { ekSymbol = "house.fill" }
                    else if name.contains("school") || name.contains("uni") || name.contains("college") { ekSymbol = "graduationcap.fill" }
                    else if name.contains("shop") || name.contains("cart") || name.contains("buy") { ekSymbol = "cart.fill" }
                    else if name.contains("health") || name.contains("gym") || name.contains("fit") { ekSymbol = "heart.fill" }
                    else if name.contains("travel") || name.contains("trip") || name.contains("flight") { ekSymbol = "airplane" }
                    else if name.contains("music") { ekSymbol = "music.note" }
                    else if name.contains("book") || name.contains("read") { ekSymbol = "book.fill" }
                }
                
                if let match = dynamicCategories.first(where: { $0.appleReminderListIdentifier == ekCal.calendarIdentifier }) {
                    match.name = ekCal.title
                    match.colorHex = hex
                    
                    if let appleIcon = ekSymbol {
                        match.iconName = appleIcon
                    } else if match.iconName == "list.bullet" {
                        match.iconName = "list.bullet"
                    }
                } else {
                    let newCat = TaskCategory(
                        name: ekCal.title, 
                        colorHex: hex, 
                        iconName: ekSymbol ?? "list.bullet", 
                        appleReminderListIdentifier: ekCal.calendarIdentifier
                    )
                    context.insert(newCat)
                    dynamicCategories.append(newCat)
                }
            }
            
            // Save categories immediately so they appear even if reminder fetch is slow
            try? context.save()
            self.onUpdateUI?()
            
            // 2. Sync Reminders (both Incomplete and Completed)
            let incompletePredicate = self.eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
            let completedPredicate = self.eventStore.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: nil)
            
            let group = DispatchGroup()
            let syncQueue = DispatchQueue(label: "com.app.remindersync")
            var allFetchedReminders: [EKReminder] = []
            
            group.enter()
            self.eventStore.fetchReminders(matching: incompletePredicate) { fetched in
                if let fetched = fetched {
                    syncQueue.async {
                        allFetchedReminders.append(contentsOf: fetched)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.enter()
            self.eventStore.fetchReminders(matching: completedPredicate) { fetched in
                if let fetched = fetched {
                    syncQueue.async {
                        allFetchedReminders.append(contentsOf: fetched)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let latestTasks = (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
                var existingDict = [String: TodoItem]()
                for t in latestTasks where t.appleReminderIdentifier != nil {
                    existingDict[t.appleReminderIdentifier!] = t
                }
                
                let latestCategories = (try? context.fetch(FetchDescriptor<TaskCategory>())) ?? []
                
                for reminder in allFetchedReminders {
                    let id = reminder.calendarItemIdentifier
                    
                    if let existing = existingDict[id] {
                        existing.isCompleted = reminder.isCompleted
                        existing.title = reminder.title
                        
                        if let components = reminder.dueDateComponents, let date = components.date {
                            existing.hasDate = true
                            existing.hasTime = components.hour != nil
                            existing.date = date
                        } else {
                            existing.hasDate = false
                            existing.hasTime = false
                            existing.date = Date.distantFuture
                        }
                        
                        // Sync category mapping
                        if let ekCal = reminder.calendar,
                           let match = latestCategories.first(where: { $0.appleReminderListIdentifier == ekCal.calendarIdentifier }) {
                            existing.categoryRef = match
                            existing.category = match.name
                        }
                        
                        existingDict.removeValue(forKey: id)
                    } else {
                        // New task from Apple Reminders (either incomplete OR completed)
                        var categoryRef: TaskCategory? = nil
                        var categoryName: String? = nil
                        if let ekCal = reminder.calendar {
                            if let match = latestCategories.first(where: { $0.appleReminderListIdentifier == ekCal.calendarIdentifier }) {
                                categoryRef = match
                                categoryName = match.name
                            }
                        }
                        
                        var hasTime = false
                        var hasDate = false
                        var taskDate = Date.distantFuture
                        if let components = reminder.dueDateComponents, let date = components.date {
                            hasDate = true
                            taskDate = date
                            hasTime = (components.hour != nil)
                        }
                        
                        let newTask = TodoItem(
                            title: reminder.title,
                            date: taskDate,
                            isCompleted: reminder.isCompleted,
                            category: categoryName,
                            hasTime: hasTime,
                            hasDate: hasDate,
                            appleReminderIdentifier: id,
                            categoryRef: categoryRef
                        )
                        context.insert(newTask)
                    }
                }
                
                // Remaining tasks in existingDict were deleted in Reminders app
                for (_, taskToDelete) in existingDict {
                    context.delete(taskToDelete)
                }
                
                try? context.save()
                self.onUpdateUI?()
            }
        }
    }
    
    private func loadEvents() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Event>()
        if let fetched = try? context.fetch(descriptor) {
            self.events = fetched
            updateDaysInMonth()
        }
    }
    
    /// Returns both local app events and Apple Calendar events for the given date
    func events(for date: Date) -> [Event] {
        var dayEvents = events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        dayEvents.sort { $0.date < $1.date }
        return dayEvents
    }
    
    /// Returns both local app events and Apple Calendar events for the given date AND hour
    func events(for date: Date, hour: Int) -> [Event] {
        // We reuse the central `events(for:)` which fetches local + Apple calendars,
        // and just filter down to the specific hour we care about.
        let allDayEvents = events(for: date)
        
        return allDayEvents.filter { event in
            let eventHour = calendarHelper.hoursFromDate(date: event.date)
            return eventHour == hour
        }
    }
    
    func upcomingEvents() -> [Event] {
        let start = Date()
        let end = calendarHelper.addDays(date: start, days: 7)
        
        return events.filter { $0.date >= start && $0.date <= end }
            .sorted { $0.date < $1.date }
    }
    
    func groupedUpcomingItems(context: ModelContext) -> [(Date, [Event], [TodoItem])] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = calendarHelper.addDays(date: start, days: 14)
        
        let upcEvents = events.filter { $0.date >= start && $0.date <= end }
        
        let descriptor = FetchDescriptor<TodoItem>()
        let allTasks = (try? context.fetch(descriptor)) ?? []
        let upcTasks = allTasks.filter { !$0.isCompleted && $0.hasDate && $0.date >= start && $0.date <= end }
        
        var datesSet = Set<Date>()
        var eventsDict = [Date: [Event]]()
        var tasksDict = [Date: [TodoItem]]()
        
        for e in upcEvents {
            let d = Calendar.current.startOfDay(for: e.date)
            datesSet.insert(d)
            eventsDict[d, default: []].append(e)
        }
        for t in upcTasks {
            let d = Calendar.current.startOfDay(for: t.date)
            datesSet.insert(d)
            tasksDict[d, default: []].append(t)
        }
        
        var result = [(Date, [Event], [TodoItem])]()
        for d in datesSet.sorted() {
            let sortedEvents = (eventsDict[d] ?? []).sorted { $0.date < $1.date }
            let sortedTasks = (tasksDict[d] ?? []).sorted { $0.date < $1.date }
            result.append((d, sortedEvents, sortedTasks))
        }
        return result
    }

    
    func searchAllEvents(query: String) -> [Event] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return upcomingEvents()
        }
        
        let lowercasedQuery = query.lowercased()
        
        // 1. Search local user events (which includes synced Apple events)
        let matchedEvents = events.filter { 
            $0.name.localizedStandardContains(lowercasedQuery) || 
            ($0.locationName?.localizedStandardContains(lowercasedQuery) ?? false)
        }
        
        // Final safety check: Unique by apple ID if present, otherwise by SwiftData ID
        var seenIDs = Set<String>()
        var uniqueEvents = [Event]()
        
        for event in matchedEvents.sorted(by: { $0.date < $1.date }) {
            let identifier = event.appleCalendarEventIdentifier ?? event.id.uuidString
            if !seenIDs.contains(identifier) {
                seenIDs.insert(identifier)
                uniqueEvents.append(event)
            }
        }
        
        return uniqueEvents
    }
    
    // MARK: - Date Manipulation logic
    
    /// Moves the selected date forward by one month and recalculates the days.
    func nextMonth() {
        selectedDate = calendarHelper.plusMonth(date: selectedDate)
        updateDaysInMonth()
    }
    
    /// Moves the selected date backward by one month and recalculates the days.
    func previousMonth() {
        selectedDate = calendarHelper.minusMonth(date: selectedDate)
        updateDaysInMonth()
    }
    
    /// Returns a formatted string for the month label (e.g. "March 2026")
    func monthYearString() -> String {
        return calendarHelper.monthString(date: selectedDate) + " " + calendarHelper.yearString(date: selectedDate)
    }
    
    // MARK: - WeatherKit Integration
    
    var onUpdateUI: (() -> Void)?
    private let locationManager = CLLocationManager()
    
    private func fetchWeatherForecast() {
        guard let location = locationManager.location else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        Task {
            do {
                let data = try await WeatherManager.shared.fetchWeatherData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.weatherData = data
                    
                    // Populate calendar cell icons from daily forecasts
                    for calendarDay in self.totalSquares {
                        if let forecast = data.dailyForecast(for: calendarDay.date) {
                            calendarDay.weatherIconName = WeatherManager.shared.sfSymbolName(for: forecast.weatherCode)
                        }
                    }
                    
                    self.onUpdateUI?()
                }
            } catch {
                print("Failed to fetch weather: \(error.localizedDescription)")
            }
        }
    }
    
    /// Returns today's daily forecast
    func todayWeather() -> DailyForecast? {
        return weatherData?.dailyForecast(for: Date())
    }
    
    /// Returns hourly forecasts for a specific date
    func hourlyForecast(for date: Date) -> [HourlyForecast] {
        return weatherData?.hourlyForecasts(for: date) ?? []
    }
    
    /// Returns the daily forecast for the selected date
    func selectedDateWeather() -> DailyForecast? {
        return weatherData?.dailyForecast(for: selectedDate)
    }
    
    // MARK: - Grid Calculation
    
    /// Recalculates the `totalSquares` array with exactly 42 items (6 rows of 7 days)
    /// to represent the current month as well as the padding days from the previous and next months.
    func updateDaysInMonth() {
        totalSquares.removeAll()
        
        // 1. Get properties of the current month
        let daysInMonth = calendarHelper.daysInMonth(date: selectedDate)
        let firstDayOfMonth = calendarHelper.firstOfMonth(date: selectedDate)
        let startingSpaces = calendarHelper.weekDay(date: firstDayOfMonth)
        
        // 2. Get properties of the previous month (for leading padding)
        let prevMonth = calendarHelper.minusMonth(date: selectedDate)
        let daysInPrevMonth = calendarHelper.daysInMonth(date: prevMonth)
        
        // Pre-fetch uncompleted tasks to populate the calendar indicators
        var activeTaskDates = [Date: String]()
        if let context = modelContext {
            let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { !$0.isCompleted })
            let activeTasks = (try? context.fetch(descriptor)) ?? []
            for task in activeTasks {
                let startOfDay = Calendar.current.startOfDay(for: task.date)
                if activeTaskDates[startOfDay] == nil {
                    activeTaskDates[startOfDay] = task.categoryRef?.colorHex ?? "#0A84FF" // fallback to blue
                }
            }
        }
        
        // 3. Generate exactly 42 days for the grid (6 weeks x 7 days)
        var count: Int = 1
        
        while count <= 42 {
            let calendarDay = CalendarDay()
            
            if count <= startingSpaces {
                // Days from the PREVIOUS month
                let prevMonthDay = daysInPrevMonth - startingSpaces + count
                calendarDay.day = String(prevMonthDay)
                calendarDay.month = .previous
                // Calculate actual date
                calendarDay.date = calendarHelper.addDays(date: firstDayOfMonth, days: count - startingSpaces - 1)
            } else if count - startingSpaces > daysInMonth {
                // Days from the NEXT month
                calendarDay.day = String(count - daysInMonth - startingSpaces)
                calendarDay.month = .next
                // Calculate actual date
                calendarDay.date = calendarHelper.addDays(date: firstDayOfMonth, days: count - startingSpaces - 1)
            } else {
                // Days from the CURRENT month
                calendarDay.day = String(count - startingSpaces)
                calendarDay.month = .current
                // Calculate actual date
                calendarDay.date = calendarHelper.addDays(date: firstDayOfMonth, days: count - startingSpaces - 1)
            }
            
            // Check if there are any events on this specific date
            calendarDay.hasEvents = !events(for: calendarDay.date).isEmpty
            
            // Check if there are any active tasks for this specific date
            let startOfCalendarDay = Calendar.current.startOfDay(for: calendarDay.date)
            if let colorHex = activeTaskDates[startOfCalendarDay] {
                calendarDay.hasTasks = true
                calendarDay.taskColorHex = colorHex
            } else {
                calendarDay.hasTasks = false
            }
            
            totalSquares.append(calendarDay)
            count += 1
        }
        // Async fetch weather to populate icons
        fetchWeatherForecast()
    }
    
    // MARK: - Core Sync Engine
    
    private func syncAppleCalendars() {
        guard !isSyncSuppressed else { return }
        guard let context = modelContext else { return }
        
        // Pull events from a year back to two years ahead
        let startDate = calendarHelper.addDays(date: Date(), days: -365)
        let endDate = calendarHelper.addDays(date: Date(), days: 365 * 2)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let ekEvents = self.eventStore.events(matching: predicate)
            
            DispatchQueue.main.async {
                let localEvents = (try? context.fetch(FetchDescriptor<Event>())) ?? []
                
                var seenTitleDates = [String: Event]()
                var localDict = [String: Event]()
                
                // 1. Proactively deduplicate local storage based on Title+Date
                for e in localEvents where e.appleCalendarEventIdentifier != nil {
                    let dateString = String(format: "%.0f", e.date.timeIntervalSince1970)
                    let key = "\(e.name)_\(dateString)"
                    
                    if let _ = seenTitleDates[key] {
                        // Duplicate found in SwiftData! Delete the stray copy.
                        context.delete(e)
                    } else {
                        seenTitleDates[key] = e
                        localDict[e.appleCalendarEventIdentifier!] = e
                    }
                }
                
                // 2. Process incoming Apple Calendar events
                for ekEvent in ekEvents {
                    guard let id = ekEvent.eventIdentifier else { continue }
                    
                    let dateString = String(format: "%.0f", ekEvent.startDate.timeIntervalSince1970)
                    let key = "\(ekEvent.title ?? "")_\(dateString)"
                    
                    // Match by direct ID or fallback to Title+Date
                    var existing = localDict[id]
                    if existing == nil {
                        existing = seenTitleDates[key]
                    }
                    
                    if let existing = existing {
                        existing.name = ekEvent.title
                        existing.date = ekEvent.startDate
                        existing.endDate = ekEvent.endDate
                        existing.isAllDay = ekEvent.isAllDay
                        existing.locationName = ekEvent.location
                        
                        let oldId = existing.appleCalendarEventIdentifier
                        existing.appleCalendarEventIdentifier = id
                        
                        // Mark as processed so we don't delete them
                        seenTitleDates.removeValue(forKey: key)
                        if let oldId = oldId {
                            localDict.removeValue(forKey: oldId)
                        }
                        localDict.removeValue(forKey: id)
                        
                    } else {
                        // Create new local event tied to Apple Calendar
                        let newEvent = Event(
                            name: ekEvent.title,
                            date: ekEvent.startDate,
                            endDate: ekEvent.endDate,
                            isAllDay: ekEvent.isAllDay,
                            locationName: ekEvent.location,
                            isReminderSet: false,
                            appleCalendarEventIdentifier: id
                        )
                        context.insert(newEvent)
                    }
                }
                
                // 3. Delete leftover synced events not in Apple Calendar anymore
                for (_, missingLocalEvent) in seenTitleDates {
                    context.delete(missingLocalEvent)
                }
                
                try? context.save()
                self.loadEvents() // Trigger an update array operation
            }
        }
    }
    

    
    // MARK: - Helpers
    private func fetchEKReminder(withIdentifier id: String, completion: @escaping (EKReminder?) -> Void) {
        if let cached = eventStore.calendarItem(withIdentifier: id) as? EKReminder {
            completion(cached)
            return
        }
        
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            let found = reminders?.first(where: { $0.calendarItemIdentifier == id })
            DispatchQueue.main.async {
                completion(found)
            }
        }
    }
}
