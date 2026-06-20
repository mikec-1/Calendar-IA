import SwiftUI

struct CalendarCellView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var day: CalendarDay
    
    var body: some View {
        VStack(spacing: 4) {
            if let iconName = day.weatherIconName {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                    .symbolRenderingMode(.multicolor)
                    .padding(.bottom, -2) // slight pull down
            }
            
            Text(day.day)
                .font(.system(size: 20, weight: day.month == .current ? .bold : .regular, design: .rounded))
                .foregroundColor(isToday ? .white : textColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isToday ? themeManager.primaryAccent : Color.clear)
                )
            
            HStack(spacing: 2) {
                if day.hasEvents {
                    Circle()
                        .fill(themeManager.primaryAccent)
                        .frame(width: 6, height: 6)
                }
                
                if day.hasTasks {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(day.taskColorHex != nil ? Color(hex: day.taskColorHex!) : themeManager.secondaryAccent)
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(day.month == .current ? Theme.backgroundSecondary : Color.clear)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: day.hasEvents)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: day.hasTasks)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: day.weatherIconName)
    }
    
    private var textColor: Color {
        if day.month == .current {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
}
