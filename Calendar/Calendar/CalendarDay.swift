import Foundation

class CalendarDay: Identifiable, ObservableObject {
    let id = UUID()
    @Published var day: String!
    @Published var month: Month!
    @Published var date: Date!
    @Published var hasEvents: Bool = false
    @Published var hasTasks: Bool = false
    @Published var taskColorHex: String? = nil
    @Published var weatherIconName: String? = nil
    
    enum Month {
        case previous
        case current
        case next
    }
}
