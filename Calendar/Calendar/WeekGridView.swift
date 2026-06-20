import SwiftUI

struct WeekGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDay: CalendarDay?
    @State private var showingAddEvent = false
    @State private var showingAddTask = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    // Filter to just one week of squares
    var weeklySquares: [CalendarDay] {
        let allDays = viewModel.totalSquares
        guard !allDays.isEmpty else { return [] }
        
        let targetDate = viewModel.selectedDate
        let rowIndex = allDays.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) ?? 0
        let weekStart = (rowIndex / 7) * 7
        let weekEnd = min(weekStart + 7, allDays.count)
        
        return Array(allDays[weekStart..<weekEnd])
    }
    
    private var weekHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: viewModel.selectedDate)
        let weekOfYear = Calendar.current.component(.weekOfYear, from: viewModel.selectedDate)
        return "\(monthYear) • Wk \(weekOfYear)"
    }
    
    private var selectedDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundBase.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    
                    // Week strip
                    
                    // Week navigation header
                    HStack {
                        Button(action: {
                            generator.impactOccurred()
                            viewModel.navigatingForward = false
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: viewModel.selectedDate) ?? viewModel.selectedDate
                                viewModel.updateDaysInMonth()
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.primaryAccent)
                        }
                        
                        Spacer()
                        
                        Text(weekHeaderString)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .animation(.none, value: viewModel.selectedDate)
                        
                        Spacer()
                        
                        Button(action: {
                            generator.impactOccurred()
                            viewModel.navigatingForward = true
                            viewModel.navigationID += 1
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: viewModel.selectedDate) ?? viewModel.selectedDate
                                viewModel.updateDaysInMonth()
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.primaryAccent)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Weekday labels
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // Week day cells
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(weeklySquares) { calendarDay in
                            let isSelected = Calendar.current.isDate(calendarDay.date, inSameDayAs: viewModel.selectedDate)
                            
                            CalendarCellView(day: calendarDay)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? themeManager.primaryAccent.opacity(0.8) : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    generator.impactOccurred()
                                    viewModel.selectedDate = calendarDay.date
                                    selectedDay = calendarDay
                                }
                        }
                    }
                    .padding(.horizontal)
                    .customHorizontalSwipe {
                        generator.impactOccurred()
                        viewModel.navigatingForward = true
                        viewModel.navigationID += 1
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: viewModel.selectedDate) ?? viewModel.selectedDate
                            viewModel.updateDaysInMonth()
                        }
                    } onInnerSwipeRight: {
                        generator.impactOccurred()
                        viewModel.navigatingForward = false
                        viewModel.navigationID += 1
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: viewModel.selectedDate) ?? viewModel.selectedDate
                            viewModel.updateDaysInMonth()
                        }
                    }
                    
                    Divider()
                        .padding(.top, 6)
                    
                    // Day detail with a sticky header
                    Section(header: stickyDayHeader) {
                        DayInlineView(isEmbedded: true)
                            .frame(minHeight: UIScreen.main.bounds.height * 0.7)
                            .customHorizontalSwipe {
                                // swipe left moves to the next day
                                generator.impactOccurred()
                                viewModel.navigatingForward = true
                                viewModel.navigationID += 1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                                    viewModel.updateDaysInMonth()
                                }
                            } onInnerSwipeRight: {
                                // swipe right moves to the previous day
                                generator.impactOccurred()
                                viewModel.navigatingForward = false
                                viewModel.navigationID += 1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                                    viewModel.updateDaysInMonth()
                                }
                            }
                    }
                }
                .padding(.bottom, 80)
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
        .sheet(isPresented: $showingAddEvent) {
            AddEventSheet(initialDate: viewModel.selectedDate)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(initialDate: viewModel.selectedDate)
        }
    }
    
    // Sticky day header that pins when scrolling
    private var stickyDayHeader: some View {
        HStack {
            Text(selectedDayString)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                showingAddEvent = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.primaryAccent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Theme.backgroundBase)
    }
}
