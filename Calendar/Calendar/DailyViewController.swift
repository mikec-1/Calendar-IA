// Import the UIKit framework
import UIKit

// Class definition for DailyViewController, a UIViewController subclass 
// conforming to the UITableViewDelegate and UITableViewDataSource protocols.
class DailyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Outlets for the day label, hour table view, and day of the week label
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var hourTableView: UITableView!
    @IBOutlet weak var dayOfWeekLabel: UILabel!
    
    // Action for the next day button
    @IBAction func nextDayAction(_ sender: Any) {
        // Increment the selected date by one day
        selectedDate = CalendarHelper().addDays(date: selectedDate, days: 1)
        // Update the day view
        setDayView()
    }
    
    // Action for the previous day button
    @IBAction func previousDayAction(_ sender: Any) {
        // Decrement the selected date by one day
        selectedDate = CalendarHelper().addDays(date: selectedDate, days: -1)
        // Update the day view
        setDayView()
    }
    
    // An array to store the hours in a day
    var hours = [Int]()
    
    // Overridden viewDidLoad method
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize the hours
        initTime()
    }
    
    // Overridden viewDidAppear method
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Update the day view
        setDayView()
    }
    
    // Initializes the hours in a day
    func initTime() {
        for hour in 0...23 {
            hours.append(hour)
        }
    }
    
    // Updates the day view
    func setDayView() {
        // Set the day label text
        dayLabel.text = CalendarHelper().monthDayString(date: selectedDate)
        // Set the day of the week label text
        dayOfWeekLabel.text = CalendarHelper().weekDayAsString(date: selectedDate)
        // Reload the hour table view data
        hourTableView.reloadData()
    }
    
    // UITableViewDataSource method to return the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of hours in the hours array
        return hours.count
    }
    
    // Helper method to set events for a given cell and events array
    func setEvents(_ cell: DailyCell, _ events: [Event]) {
        // Hide all events in the cell
        hideAll(cell)
        
        // Switch based on the number of events
        switch events.count {
            // One event
        case 1: 
            setEvent1(cell, events[0])
            // Two events
        case 2: 
            setEvent1(cell, events[0])
            setEvent2(cell, events[1])
            // Three events
        case 3:
            setEvent1(cell, events[0])
            setEvent2(cell, events[1])
            setEvent3(cell, events[2])
            //If there are more than 3 events, set first two and count for more
        case let count where count > 3:
            setEvent1(cell, events[0]) // Set first event
            setEvent2(cell, events[1]) // Set second event
            setMoreEvents(cell, events.count - 2) // Set count for more events
            
            //No events, break
        default:
            break
        }
    }
    //Set the first event's details
    func setEvent1(_ cell: DailyCell, _ event: Event) {
        cell.event1.isHidden = false //Unhide the first event label
        let locationStr = event.locationName != nil ? " - \(event.locationName!)" : ""
        cell.event1.text = event.name + locationStr //Set event name as the text for the first event label
    }
    
    //Set the second event's details
    func setEvent2(_ cell: DailyCell, _ event: Event) {
        cell.event2.isHidden = false //Unhide the second event label
        let locationStr = event.locationName != nil ? " - \(event.locationName!)" : ""
        cell.event2.text = event.name + locationStr //Set event name as the text for the second event label
    }
    
    //Set the third event's details
    func setEvent3(_ cell: DailyCell, _ event: Event) {
        cell.event3.isHidden = false //Unhide the third event label
        let locationStr = event.locationName != nil ? " - \(event.locationName!)" : ""
        cell.event3.text = event.name + locationStr //Set event name as the text for the third event label
    }
    
    //Set more events count
    func setMoreEvents(_ cell: DailyCell, _ count: Int) {
        cell.event3.isHidden = false //Unhide the third event label
        cell.event3.text = String(count) + " More Events" //Set count of more events as the text for the third event label
    }
    
    //Table view delegate method to return a cell for each row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellDailyID") as! DailyCell //Get cell of type DailyCell
        let hour = hours[indexPath.row] //Get hour for the current row
        cell.time.text = formatHour(hour: hour) //Set the time label text to formatted hour
        
        // Fetch events for this hour from the shared ViewModel
        let events = CalendarViewModel.shared.events(for: selectedDate, hour: hour)
        setEvents(cell, events) //Set the events for the cell
        
        return cell //Return the cell
    }
    
    //Helper function to hide all events labels
    func hideAll(_ cell: DailyCell) {
        cell.event1.isHidden = true //Hide first event label
        cell.event2.isHidden = true //Hide second event label
        cell.event3.isHidden = true //Hide third event label
    }
    
    func formatHour(hour: Int) -> String {
        return String(format: "%02d:%02d", hour, 0) //Format the string
    }
}

