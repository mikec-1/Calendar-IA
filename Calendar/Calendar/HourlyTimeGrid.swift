import SwiftUI

struct HourlyTimeGrid: View {
    let date: Date
    let events: [Event]
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // Configurable dimensions
    let hourHeight: CGFloat = 60
    let timeColumnWidth: CGFloat = 60
    let startHour = 0
    let endHour = 24
    
    @State private var currentTimeOffset: CGFloat = 0
    @Binding var eventToFocusID: UUID?
    @State private var didInitialScroll = false
    
    // Tap-to-edit: selected event opens edit sheet
    @State private var tappedEvent: Event?
    // Tap-to-create: tapping empty slot opens new event sheet at that hour
    @State private var newEventDate: Date?
    @State private var showingNewEvent = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Background Grid Lines (tappable for create)
                    VStack(spacing: 0) {
                        ForEach(startHour...endHour, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 0) {
                                Text(timeLabel(for: hour))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(width: timeColumnWidth, alignment: .trailing)
                                    .padding(.trailing, 8)
                                    .offset(y: -6)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                
                                Spacer()
                            }
                            .frame(height: hourHeight, alignment: .top)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Tap on empty hour slot creates event at that time
                                let cal = Calendar.current
                                var components = cal.dateComponents([.year, .month, .day], from: date)
                                components.hour = hour
                                components.minute = 0
                                if let slotDate = cal.date(from: components) {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    newEventDate = slotDate
                                    showingNewEvent = true
                                }
                            }
                        }
                    }
                    
                    // Events Layer
                    GeometryReader { geo in
                        let regularEvents = events.filter { !$0.isAllDay }
                        let allDayEvents = events.filter { $0.isAllDay }
                        
                        // All-day events at the top
                        if !allDayEvents.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(allDayEvents) { event in
                                    allDayBlock(for: event, totalWidth: geo.size.width)
                                        .onTapGesture {
                                            tappedEvent = event
                                        }
                                }
                            }
                            .offset(y: 5)
                            .padding(.bottom, 10)
                        }
                        
                        // Regular timed events
                        ForEach(regularEvents) { event in
                            let dims = calculateDimensions(for: event)
                            let blockWidth = geo.size.width - timeColumnWidth - 16
                            
                            eventBlock(for: event, height: dims.1)
                                .id(event.id)
                                .draggableEvent(event, dims: dims, width: blockWidth, hourHeight: hourHeight)
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    tappedEvent = event
                                }
                        }
                        
                        // Current time indicator
                        if Calendar.current.isDateInToday(date) {
                            currentTimeLine()
                                .id("currentTimeLine")
                        }
                    }
                    .padding(.leading, timeColumnWidth)
                }
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
            .onAppear {
                updateCurrentTimeIndicator()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let focusId = eventToFocusID {
                        withAnimation {
                            proxy.scrollTo(focusId, anchor: .center)
                            eventToFocusID = nil
                        }
                    } else if Calendar.current.isDateInToday(date) && !didInitialScroll {
                        withAnimation {
                            proxy.scrollTo("currentTimeLine", anchor: .center)
                        }
                        didInitialScroll = true
                    }
                }
            }
            .onChange(of: eventToFocusID) { newID in
                if let focusId = newID {
                    withAnimation {
                        proxy.scrollTo(focusId, anchor: .center)
                        eventToFocusID = nil
                    }
                }
            }
        }
        // MARK: - Tap-to-edit sheet
        .sheet(item: $tappedEvent) { event in
            AddEventSheet(initialDate: event.date, eventToEdit: event)
                .environmentObject(viewModel)
        }
        // MARK: - Tap-to-create sheet
        .sheet(isPresented: $showingNewEvent) {
            if let slotDate = newEventDate {
                AddEventSheet(initialDate: slotDate)
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - All-Day Block
    @ViewBuilder
    private func allDayBlock(for event: Event, totalWidth: CGFloat) -> some View {
        let blockColor = themeManager.primaryAccent

        HStack(spacing: 6) {
            Text(event.name)
                .font(.caption)
                .bold()
                .lineLimit(1)
            
            if event.notes != nil {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: totalWidth - timeColumnWidth - 16, alignment: .leading)
        .background(blockColor.opacity(0.85))
        .cornerRadius(6)
        .foregroundColor(.white)
        .padding(.leading, 8)
    }
    
    // MARK: - Dimensions
    private func calculateDimensions(for event: Event) -> (CGFloat, CGFloat) {
        let cal = Calendar.current
        let startComponents = cal.dateComponents([.hour, .minute], from: event.date)
        let endComponents = cal.dateComponents([.hour, .minute], from: event.endDate)
        
        let startHourValue = CGFloat(startComponents.hour ?? 0)
        let startMinuteValue = CGFloat(startComponents.minute ?? 0)
        let endHourValue = CGFloat(endComponents.hour ?? 0)
        let endMinuteValue = CGFloat(endComponents.minute ?? 0)
        
        let startTimeInHours = startHourValue + (startMinuteValue / 60.0)
        var endTimeInHours = endHourValue + (endMinuteValue / 60.0)
        
        if endTimeInHours <= startTimeInHours {
            if cal.isDate(event.endDate, inSameDayAs: event.date) {
                endTimeInHours = startTimeInHours + 1.0
            } else {
                endTimeInHours = 24.0
            }
        }
        
        let durationInHours = endTimeInHours - startTimeInHours
        let yOffset = startTimeInHours * hourHeight
        let height = max(durationInHours * hourHeight, 15)
        
        return (yOffset, height)
    }

    // MARK: - Event Block
    @ViewBuilder
    private func eventBlock(for event: Event, height: CGFloat) -> some View {
        let blockColor = themeManager.primaryAccent 
        
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(event.name)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                
                if event.notes != nil {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if height > 30 {
                if let location = event.locationName, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .lineLimit(1)
                } else {
                    Text(eventTimeString(start: event.date, end: event.endDate))
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(blockColor.opacity(0.85))
        .cornerRadius(6)
        .foregroundColor(.white)
        .shadow(color: blockColor.opacity(0.3), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
    }
    
    // MARK: - Current Time Line
    @ViewBuilder
    private func currentTimeLine() -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)
            
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .offset(y: currentTimeOffset - 4)
    }
    
    private func updateCurrentTimeIndicator() {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.hour, .minute], from: now)
        let h = CGFloat(comps.hour ?? 0)
        let m = CGFloat(comps.minute ?? 0)
        currentTimeOffset = (h + (m / 60.0)) * hourHeight
    }
    
    private func timeLabel(for hour: Int) -> String {
        if hour == 0 || hour == 24 { return "12 AM" }
        if hour == 12 { return "12 PM" }
        if hour > 12 { return "\(hour - 12) PM" }
        return "\(hour) AM"
    }
    
    private func eventTimeString(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

// MARK: - Drag-and-Drop Modifier

/// Makes an event block long-press-draggable on the HourlyTimeGrid.
/// Drag vertically to change time; snaps to 15-minute intervals.
/// Bottom resize handle adjusts duration.
struct DraggableEventModifier: ViewModifier {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    let event: Event
    let dims: (CGFloat, CGFloat) // (yOffset, height)
    let width: CGFloat
    let hourHeight: CGFloat
    
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    @State private var isResizingBottom = false
    @State private var resizeOffset: CGFloat = 0
    
    /// Snap fractional hours to the nearest 15-minute interval
    private func snap(_ hours: CGFloat) -> CGFloat {
        (hours * 4).rounded() / 4
    }
    
    private func offsetToHours(_ offset: CGFloat) -> CGFloat {
        offset / hourHeight
    }
    
    private func startHoursOf(_ date: Date) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) + CGFloat(c.minute ?? 0) / 60.0
    }
    
    private func dateForHours(_ hours: CGFloat, on referenceDate: Date) -> Date {
        let h = Int(hours)
        let m = Int((hours - CGFloat(h)) * 60)
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: referenceDate) ?? referenceDate
    }
    
    var snappedYOffset: CGFloat {
        if isDragging {
             let hoursDelta = snap(offsetToHours(dragOffset))
             return max(0, dims.0 + (hoursDelta * hourHeight))
        }
        return dims.0
    }
    
    var snappedHeight: CGFloat {
        if isResizingBottom {
             let hoursDelta = snap(offsetToHours(resizeOffset))
             let newHeight = dims.1 + (hoursDelta * hourHeight)
             return max(15, newHeight)
        }
        return dims.1
    }
    
    func body(content: Content) -> some View {
        content
            // Only size the frame inside the modifier
            .frame(width: width, height: snappedHeight)
            .scaleEffect(isDragging ? 1.04 : 1.0)
            .shadow(color: isDragging ? Color.black.opacity(0.3) : Color.clear, radius: isDragging ? 8 : 0, y: isDragging ? 4 : 0)
            .opacity(isDragging ? 0.9 : 1.0)
            // Bottom resize handle overlay onto the exact frame
            .overlay(alignment: .bottom) {
                if !isDragging {
                    ResizeHandle()
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    isResizingBottom = true
                                    resizeOffset = value.translation.height
                                }
                                .onEnded { value in
                                    let hoursDelta = snap(offsetToHours(value.translation.height))
                                    let currentEndHours = startHoursOf(event.endDate)
                                    let minEndHours = startHoursOf(event.date) + 0.25
                                    let newEndHours = max(minEndHours, min(24.0, currentEndHours + hoursDelta))
                                    
                                    let newEndDate = dateForHours(newEndHours, on: event.date)
                                    
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    viewModel.moveEvent(event, to: event.date, newEndDate: newEndDate)
                                    
                                    withAnimation {
                                        isResizingBottom = false
                                        resizeOffset = 0
                                    }
                                }
                        )
                }
            }
            // Position the entire block and handle together 
            .offset(y: snappedYOffset)
            .padding(.leading, 8)
            .zIndex(isDragging ? 100 : 0)
            // Long-press + drag to move
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onEnded { _ in
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.easeOut(duration: 0.15)) {
                            isDragging = true
                        }
                    }
                    .sequenced(before: DragGesture(minimumDistance: 2))
                    .onChanged { value in
                        switch value {
                        case .second(true, let drag):
                            if let drag = drag {
                                dragOffset = drag.translation.height
                            }
                        default:
                            break
                        }
                    }
                    .onEnded { value in
                        switch value {
                        case .second(true, let drag):
                            if let drag = drag {
                                let hoursDelta = snap(offsetToHours(drag.translation.height))
                                let currentStartHours = startHoursOf(event.date)
                                let newStartHours = max(0, min(23.75, currentStartHours + hoursDelta))
                                let newStartDate = dateForHours(newStartHours, on: event.date)
                                
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                viewModel.moveEvent(event, to: newStartDate)
                            }
                        default:
                            break
                        }
                        
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDragging = false
                            dragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: snappedYOffset)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: snappedHeight)
    }
}

/// Small drag handle shown at the bottom edge of an event for resizing duration.
struct ResizeHandle: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.8))
            .frame(width: 36, height: 4)
            .padding(.bottom, 4)
            .contentShape(Rectangle().inset(by: -10)) // Make touch area larger
    }
}

extension View {
    func draggableEvent(_ event: Event, dims: (CGFloat, CGFloat), width: CGFloat, hourHeight: CGFloat) -> some View {
        self.modifier(DraggableEventModifier(event: event, dims: dims, width: width, hourHeight: hourHeight))
    }
}
