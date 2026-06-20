import SwiftUI
import SwiftData

struct EventSearchView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var searchText = ""
    
    var filteredEvents: [Event] {
        viewModel.searchAllEvents(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundBase.ignoresSafeArea()
                
                List {
                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        ForEach(filteredEvents) { event in
                            eventRow(for: event)
                                .onTapGesture {
                                    navigateToEvent(event)
                                }
                        }
                    } else if filteredEvents.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                                .padding()
                            Text("No events found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredEvents) { event in
                            eventRow(for: event)
                                .onTapGesture {
                                    navigateToEvent(event)
                                }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(searchText.trimmingCharacters(in: .whitespaces).isEmpty ? "Upcoming events" : "Search Events")
            .searchable(text: $searchText, prompt: "Search by title or location")
        }
    }
    
    private func navigateToEvent(_ event: Event) {
        viewModel.selectedDate = event.date
        viewModel.calendarMode = .week
        viewModel.activeTab = 0 // Calendar tab
        viewModel.eventToFocusID = event.id
    }
    
    @ViewBuilder
    private func eventRow(for event: Event) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .font(.headline)
            
            HStack {
                Text(formattedDate(event.date))
                if let loc = event.locationName {
                    Text("• \(loc)")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
