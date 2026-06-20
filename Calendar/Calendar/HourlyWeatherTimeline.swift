import SwiftUI

/// A horizontally scrollable hourly weather timeline with temperature curve and precipitation bars
struct HourlyWeatherTimeline: View {
    let hourlyData: [HourlyForecast]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private let columnWidth: CGFloat = 56
    private let chartHeight: CGFloat = 60
    
    private var displayData: [HourlyForecast] {
        // Show up to 24 hours
        Array(hourlyData.prefix(24))
    }
    
    private var tempRange: (min: Double, max: Double) {
        guard !displayData.isEmpty else { return (0, 20) }
        let temps = displayData.map { $0.temperature }
        let minT = (temps.min() ?? 0) - 1
        let maxT = (temps.max() ?? 20) + 1
        return (minT, max(minT + 1, maxT))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOURLY FORECAST")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Temperature curve (drawn behind columns)
                    tempCurve
                        .padding(.top, 48) // Below icon + time
                    
                    // Hourly columns
                    HStack(spacing: 0) {
                        ForEach(Array(displayData.enumerated()), id: \.element.id) { index, hour in
                            hourColumn(hour: hour, index: index)
                                .frame(width: columnWidth)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Hour Column
    
    private func hourColumn(hour: HourlyForecast, index: Int) -> some View {
        VStack(spacing: 6) {
            // Time label
            Text(hourLabel(hour.date))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isCurrentHour(hour.date) ? themeManager.primaryAccent : .secondary)
            
            // Weather icon (small)
            Image(systemName: WeatherManager.condition(for: hour.weatherCode).sfSymbolName)
                .font(.system(size: 16))
                .foregroundColor(iconColor(for: hour.weatherCode))
                .frame(height: 20)
            
            Spacer()
                .frame(height: chartHeight)
            
            // Temperature
            Text("\(Int(hour.temperature.rounded()))°")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            // Precipitation bar
            if hour.precipProbability > 0 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(Double(hour.precipProbability) / 100.0 * 0.7 + 0.3))
                    .frame(width: 20, height: CGFloat(hour.precipProbability) / 100.0 * 20 + 2)
                
                Text("\(hour.precipProbability)%")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.blue.opacity(0.7))
            } else {
                Color.clear.frame(width: 20, height: 2)
                Color.clear.frame(height: 12)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Temperature Curve
    
    private var tempCurve: some View {
        Canvas { context, size in
            guard displayData.count >= 2 else { return }
            
            let range = tempRange
            let tempSpan = range.max - range.min
            
            var path = Path()
            
            for (i, hour) in displayData.enumerated() {
                let x = CGFloat(i) * columnWidth + columnWidth / 2
                let normalizedTemp = (hour.temperature - range.min) / tempSpan
                let y = chartHeight * (1.0 - normalizedTemp)
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    // Smooth curve using quadratic bezier
                    let prevX = CGFloat(i - 1) * columnWidth + columnWidth / 2
                    let controlX = (prevX + x) / 2
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: y))
                }
            }
            
            // Gradient fill under curve
            var fillPath = path
            let lastX = CGFloat(displayData.count - 1) * columnWidth + columnWidth / 2
            fillPath.addLine(to: CGPoint(x: lastX, y: chartHeight))
            fillPath.addLine(to: CGPoint(x: columnWidth / 2, y: chartHeight))
            fillPath.closeSubpath()
            
            let gradient = Gradient(colors: [
                Color.orange.opacity(0.15),
                Color.blue.opacity(0.05)
            ])
            context.fill(fillPath, with: .linearGradient(gradient, startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: chartHeight)))
            
            // Stroke the line
            context.stroke(path, with: .color(Color.orange.opacity(0.6)), lineWidth: 2)
            
            // Dots on current data points
            for (i, hour) in displayData.enumerated() {
                let x = CGFloat(i) * columnWidth + columnWidth / 2
                let normalizedTemp = (hour.temperature - range.min) / tempSpan
                let y = chartHeight * (1.0 - normalizedTemp)
                
                if isCurrentHour(hour.date) {
                    let dotRect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: dotRect), with: .color(Color.orange))
                    let outerRect = CGRect(x: x - 6, y: y - 6, width: 12, height: 12)
                    context.stroke(Path(ellipseIn: outerRect), with: .color(Color.orange.opacity(0.3)), lineWidth: 2)
                }
            }
        }
        .frame(height: chartHeight)
        .frame(width: CGFloat(displayData.count) * columnWidth)
    }
    
    // MARK: - Helpers
    
    private func hourLabel(_ date: Date) -> String {
        if isCurrentHour(date) { return "Now" }
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    private func isCurrentHour(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(date, equalTo: Date(), toGranularity: .hour)
    }
    
    private func iconColor(for code: Int) -> Color {
        let condition = WeatherManager.condition(for: code)
        switch condition {
        case .clear: return .yellow
        case .rain, .heavyRain, .drizzle, .freezingDrizzle, .freezingRain: return .blue
        case .snow: return Color(white: 0.7)
        case .thunderstorm: return .purple
        default: return .secondary
        }
    }
}
