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
    (Update June 2026: CocoaPods is now required for SPPermissions)

## Configuration Options

*   **UI elements:** Adjust colors, fonts, and layouts in the Interface Builder.
*   **Data storage:** Modify the way events are stored and retrieved.
*   **Notifications:** Customize notification settings and behavior.


## Update — June 2026

More than three years after the original Internal Assessment, I came back to this project and expanded it well beyond its original scope. What started as a basic calendar built while I was first learning Swift is now a much more complete time-management app.

### New features

*   **Tasks & to-dos:** categories, priorities, due dates, and completion tracking alongside events.
*   **Apple sync:** two-way sync with Apple Calendar (EventKit) and Apple Reminders, including lists and categories.
*   **Weather:** hourly and daily forecasts from the Open-Meteo API, with animated weather icons and condition-based gradient backgrounds.
*   **Redesigned calendar:** month, week, and day views plus an agenda feed, with drag-and-resize editing of events directly on the daily hourly timeline.
*   **Map & location:** a map view with location search for tagging events.
*   **Theming:** light/dark/system themes and selectable accent colors.

### Technical changes

*   Rebuilt most of the interface in **SwiftUI** (the original was UIKit + Storyboards).
*   Added **SwiftData** for local persistence.
*   Integrated **EventKit**, **MapKit**, and **CoreLocation**.
*   Migrated **FloatingPanel** from CocoaPods to the **Swift Package Manager**; **SPPermissions** remains a CocoaPod.
*   General project cleanup (stopped tracking `Pods/` and Xcode user state).

Because of these changes the app now targets **iOS 17+** (SwiftData) and is best opened via `Calendar.xcworkspace`. On first launch it requests **location** and **calendar/reminders** permissions to power the weather, map, and Apple sync features.

### See the original project

The project as it was before this update — the original 2023 IB CS IA code — is tagged and browsable here:

*   **Original (2023):** [`ib-cs-ia-2023`](https://github.com/mikec-1/Calendar-IA/tree/ib-cs-ia-2023)
*   **Everything that changed:** [compare `ib-cs-ia-2023...main`](https://github.com/mikec-1/Calendar-IA/compare/ib-cs-ia-2023...main)

**Disclaimer:** This project was built with the help of generative AI tools such as Claude Code. I used them in part as a way to learn, to expand my knowledge and to explore what's possible in Swift. The original 2023 project was written entirely by me, and the design, direction, and architecture of the newer work are my own.

## License

This project does not currently have a specified license.
