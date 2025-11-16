# Calendar-IA: iOS Calendar and Time Manager

## Description

This is an iOS application with the main idea of letting users manage their calendar and time effectively. This project was built using Swift and Xcode, and was initially developed as my Computer Science IB Internal Assessment Project.

## Key Features & Benefits

*   **Calendar View:** Easily view and navigate through days, weeks, and months.
*   **Event Creation & Management:** Quickly add, edit, and delete events with detailed information.
*   **User-Friendly Interface:** A clean and simple design for ease of use.
*   **Swift & Xcode based:** Latest iOS development tools used for optimal performance and stability.

## Prerequisites & Dependencies

To use my code, you need to have the following installed:

*   **Xcode:** Version 13.0 or higher (available on the Mac App Store).
*   **Swift:** Version 5.0 or higher (included with Xcode).
*   **CocoaPods:** (Optional but recommended for dependency management)
    ```bash
    sudo gem install cocoapods
    ```

## Usage Examples & API Documentation

My project uses standard iOS frameworks and Swift syntax. For specific API details, refer to the official Apple documentation and inline code comments.

```swift
// Example: Creating a new event
import EventKit

let eventStore = EKEventStore()

eventStore.requestAccess(to: .event) { (granted, error) in
    if granted {
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = "Meeting with Client"
        newEvent.startDate = Date()
        newEvent.endDate = Date().addingTimeInterval(3600) // One hour later
        newEvent.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(newEvent, span: .thisEvent)
            print("Event saved successfully!")
        } catch let error as NSError {
            print("Failed to save event with error : \(error)")
        }
    } else {
        print("Access to calendar not granted")
    }
}
```

## Configuration Options

*   **UI elements:** Adjust colors, fonts, and layouts in the Interface Builder.
*   **Data storage:** Modify the way events are stored and retrieved.
*   **Notifications:** Customize notification settings and behavior.


## License

This project does not currently have a specified license.
