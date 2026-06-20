import SwiftUI

struct CalendarContainerView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundBase.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("View Mode", selection: Binding(
                        get: { viewModel.calendarMode },
                        set: { newMode in
                            // Determine direction based on tab order
                            let order: [CalendarMode] = [.month, .week, .agenda]
                            let oldIndex = order.firstIndex(of: viewModel.calendarMode) ?? 0
                            let newIndex = order.firstIndex(of: newMode) ?? 0
                            viewModel.navigatingForward = newIndex > oldIndex
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.calendarMode = newMode
                            }
                        }
                    )) {
                        Text("Month").tag(CalendarMode.month)
                        Text("Week").tag(CalendarMode.week)
                        Text("Agenda").tag(CalendarMode.agenda)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    ZStack {
                        switch viewModel.calendarMode {
                        case .month:
                            MonthGridView()
                                .id("month")
                                .transition(slideTransition)
                        case .week:
                            WeekGridView()
                                .id("week")
                                .transition(slideTransition)
                        case .agenda:
                            AgendaView()
                                .id("agenda")
                                .transition(slideTransition)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.calendarMode)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
    
    private var slideTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: viewModel.navigatingForward ? .trailing : .leading),
            removal: .move(edge: viewModel.navigatingForward ? .leading : .trailing)
        )
    }
}
