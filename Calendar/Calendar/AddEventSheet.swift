import SwiftUI
import UserNotifications
import SwiftData

struct AddEventSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var viewModel: CalendarViewModel
    
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var isReminderSet: Bool = false
    @State private var showingPermissionAlert = false
    @State private var showingDeleteConfirm = false
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    @State private var editingEvent: Event?
    var initialDate: Date
    /// Called after a duplicate is created, passing the new event
    var onDuplicate: ((Event) -> Void)?
    
    init(initialDate: Date = Date(), eventToEdit: Event? = nil, onDuplicate: ((Event) -> Void)? = nil) {
        self.initialDate = initialDate
        self.onDuplicate = onDuplicate
        _startDate = State(initialValue: eventToEdit?.date ?? initialDate)
        _endDate = State(initialValue: eventToEdit?.endDate ?? initialDate.addingTimeInterval(3600))
        _isAllDay = State(initialValue: eventToEdit?.isAllDay ?? false)
        _title = State(initialValue: eventToEdit?.name ?? "")
        _location = State(initialValue: eventToEdit?.locationName ?? "")
        _notes = State(initialValue: eventToEdit?.notes ?? "")
        _isReminderSet = State(initialValue: eventToEdit?.isReminderSet ?? false)
        _editingEvent = State(initialValue: eventToEdit)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Event Details
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Location (Optional)", text: $location)
                }
                
                // MARK: - Notes
                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add notes…")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .opacity(notes.isEmpty ? 0.25 : 1)
                    }
                }
                
                // MARK: - Time & Date
                Section(header: Text("Time & Date")) {
                    Toggle("All-Day", isOn: $isAllDay)
                        .onChange(of: isAllDay) { newValue in
                            if newValue {
                                startDate = Calendar.current.startOfDay(for: startDate)
                                endDate = Calendar.current.startOfDay(for: startDate)
                            } else {
                                endDate = startDate.addingTimeInterval(3600)
                            }
                        }
                    
                    if isAllDay {
                        DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                        DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: .date)
                    } else {
                        DatePicker("Starts", selection: $startDate)
                        DatePicker("Ends", selection: $endDate, in: startDate...)
                    }
                }
                
                // MARK: - Notifications
                Section(header: Text("Notifications")) {
                    Toggle("15m Reminder", isOn: $isReminderSet)
                        .onChange(of: isReminderSet) { newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                }
                
                // MARK: - Actions (Edit mode only)
                if let event = editingEvent {
                    Section(header: Text("Actions")) {
                        // Duplicate
                        Button {
                            duplicateEvent(event)
                        } label: {
                            Label("Duplicate Event", systemImage: "doc.on.doc")
                        }
                        
                        // Move to another date
                        DatePicker(
                            "Move to Date",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .onChange(of: startDate) { newDate in
                            // Keep duration intact when moving
                            let duration = endDate.timeIntervalSince(event.date)
                            endDate = newDate.addingTimeInterval(duration)
                        }
                    }
                    
                    Section {
                        Button("Delete Event", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(editingEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveEvent()
                }
                .disabled(title.isEmpty)
                .font(.headline)
            )
            .onAppear {
                if editingEvent == nil {
                    startDate = initialDate
                    endDate = initialDate.addingTimeInterval(3600)
                }
            }
            .alert("Notification Permission Denied", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) {
                    isReminderSet = false
                }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications in Settings to receive 15-minute reminders.")
            }
            .confirmationDialog("Are you sure?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Event", role: .destructive) {
                    if let event = editingEvent {
                        deleteEvent(event)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This event will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Save
    private func saveEvent() {
        generator.impactOccurred()
        
        var finalEnd = endDate
        if isAllDay {
            finalEnd = Calendar.current.startOfDay(for: endDate)
            if finalEnd < Calendar.current.startOfDay(for: startDate) {
                finalEnd = Calendar.current.startOfDay(for: startDate)
            }
        } else {
            if finalEnd < startDate {
                finalEnd = startDate.addingTimeInterval(3600)
            }
        }
        
        if let event = editingEvent {
            event.notes = notes.isEmpty ? nil : notes
            viewModel.updateEvent(event, name: title, date: startDate, endDate: finalEnd, isAllDay: isAllDay, locationName: location.isEmpty ? nil : location, context: modelContext)
            
            if isReminderSet {
                scheduleNotification(for: event)
            }
        } else {
            let newEvent = Event(
                name: title,
                date: startDate,
                endDate: finalEnd,
                isAllDay: isAllDay,
                locationName: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                isReminderSet: isReminderSet
            )
            
            viewModel.addEvent(newEvent)
            
            if isReminderSet {
                scheduleNotification(for: newEvent)
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Duplicate
    private func duplicateEvent(_ event: Event) {
        generator.impactOccurred()
        let copy = Event(
            name: event.name + " (copy)",
            date: event.date,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            locationName: event.locationName,
            notes: event.notes,
            isReminderSet: event.isReminderSet
        )
        viewModel.addEvent(copy)
        onDuplicate?(copy)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Delete
    private func deleteEvent(_ event: Event) {
        generator.impactOccurred()
        viewModel.deleteEvent(event)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        DispatchQueue.main.async {
                            if !granted {
                                self.isReminderSet = false
                            }
                        }
                    }
                } else if settings.authorizationStatus == .denied {
                    self.showingPermissionAlert = true
                }
            }
        }
    }
    
    private func scheduleNotification(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.name) is starting in 15 minutes!"
        content.sound = .default
        
        let reminderDate = event.date.addingTimeInterval(-15 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
