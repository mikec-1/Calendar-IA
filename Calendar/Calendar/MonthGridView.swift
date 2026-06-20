import SwiftUI

struct MonthGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDay: CalendarDay?
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            Theme.backgroundBase.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Custom Header
                    HStack {
                        Button(action: {
                            generator.impactOccurred()
                            viewModel.navigatingForward = false
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.previousMonth()
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.primaryAccent)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.monthYearString())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .animation(.none, value: viewModel.selectedDate)
                        
                        Spacer()
                        
                        Button(action: {
                            generator.impactOccurred()
                            viewModel.navigatingForward = true
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.nextMonth()
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.primaryAccent)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Weekday Header
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(viewModel.totalSquares) { calendarDay in
                                CalendarCellView(day: calendarDay)
                                    .onTapGesture {
                                        generator.impactOccurred()
                                        selectedDay = calendarDay
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                        .customHorizontalSwipe {
                            generator.impactOccurred()
                            viewModel.navigatingForward = true
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.nextMonth()
                            }
                        } onInnerSwipeRight: {
                            generator.impactOccurred()
                            viewModel.navigatingForward = false
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.previousMonth()
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .sheet(item: $selectedDay) { day in
                        DayAgendaView(day: day)
                            .environmentObject(viewModel)
                    }
                }
            
            // Bottom Left Today Button Overlay
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.selectedDate = Date()
                            viewModel.updateDaysInMonth()
                        }
                    }) {
                        Text("Today")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.backgroundSecondary.opacity(0.9))
                            .foregroundColor(themeManager.primaryAccent)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
            .onAppear {
                if viewModel.totalSquares.isEmpty {
                    viewModel.updateDaysInMonth()
                }
            }
    }
}
