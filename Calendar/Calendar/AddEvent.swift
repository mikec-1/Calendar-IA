import UIKit
import UserNotifications

class EventEditViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var reminderSwitch: UISwitch!
        
    override func viewDidLoad() {
        super.viewDidLoad()
            
        datePicker.date = selectedDate
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
        
    @IBAction func saveAction(_ sender: Any) {
        let eventName = nameTextField.text ?? ""
        let locationName = locationTextField.text?.isEmpty == false ? locationTextField.text : nil
        let eventDate = datePicker.date
        let isReminderSet = reminderSwitch?.isOn ?? false
        
        if !eventName.isEmpty {
            let newEvent = Event(name: eventName, date: eventDate, locationName: locationName, isReminderSet: isReminderSet)
            CalendarViewModel.shared.addEvent(newEvent)
            
            if isReminderSet {
                scheduleNotification(for: newEvent)
            }
            
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func scheduleNotification(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.name) is starting in 15 minutes!"
        content.sound = .default
        
        // 15 minutes before event date
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
    
    class event {
        var title: String!
        var location: Location!
        var shots: Int!
        var allDay: Bool!
        var date: Date!
        
        init(title: String!, location: Location!, shots: Int!, allDay: Bool!, date: Date!) {
            self.title = title
            self.location = location
            self.shots = shots
            self.allDay = allDay
            self.date = date
        }
    }
}
