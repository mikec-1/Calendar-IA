import SwiftUI

// MARK: - Weather Color Palettes

/// Curated color palettes for each weather condition, with day/night variants
struct WeatherColors {
    
    struct Palette {
        let topDay: Color
        let bottomDay: Color
        let topNight: Color
        let bottomNight: Color
    }
    
    static func palette(for condition: WeatherCondition) -> Palette {
        switch condition {
        case .clear:
            return Palette(
                topDay: Color(red: 0.2, green: 0.6, blue: 1.0),
                bottomDay: Color(red: 1.0, green: 0.85, blue: 0.4),
                topNight: Color(red: 0.05, green: 0.1, blue: 0.3),
                bottomNight: Color(red: 0.1, green: 0.15, blue: 0.35)
            )
        case .partlyCloudy:
            return Palette(
                topDay: Color(red: 0.45, green: 0.7, blue: 1.0),
                bottomDay: Color(red: 0.85, green: 0.9, blue: 1.0),
                topNight: Color(red: 0.1, green: 0.15, blue: 0.35),
                bottomNight: Color(red: 0.15, green: 0.2, blue: 0.4)
            )
        case .cloudy:
            return Palette(
                topDay: Color(red: 0.6, green: 0.65, blue: 0.75),
                bottomDay: Color(red: 0.8, green: 0.82, blue: 0.88),
                topNight: Color(red: 0.15, green: 0.18, blue: 0.25),
                bottomNight: Color(red: 0.2, green: 0.22, blue: 0.3)
            )
        case .fog:
            return Palette(
                topDay: Color(red: 0.7, green: 0.72, blue: 0.76),
                bottomDay: Color(red: 0.85, green: 0.86, blue: 0.88),
                topNight: Color(red: 0.2, green: 0.22, blue: 0.27),
                bottomNight: Color(red: 0.25, green: 0.27, blue: 0.32)
            )
        case .drizzle, .freezingDrizzle:
            return Palette(
                topDay: Color(red: 0.4, green: 0.5, blue: 0.65),
                bottomDay: Color(red: 0.65, green: 0.72, blue: 0.82),
                topNight: Color(red: 0.1, green: 0.15, blue: 0.25),
                bottomNight: Color(red: 0.15, green: 0.2, blue: 0.3)
            )
        case .rain, .freezingRain:
            return Palette(
                topDay: Color(red: 0.3, green: 0.4, blue: 0.55),
                bottomDay: Color(red: 0.5, green: 0.58, blue: 0.7),
                topNight: Color(red: 0.08, green: 0.12, blue: 0.22),
                bottomNight: Color(red: 0.12, green: 0.18, blue: 0.28)
            )
        case .heavyRain:
            return Palette(
                topDay: Color(red: 0.25, green: 0.32, blue: 0.45),
                bottomDay: Color(red: 0.4, green: 0.48, blue: 0.6),
                topNight: Color(red: 0.06, green: 0.09, blue: 0.18),
                bottomNight: Color(red: 0.1, green: 0.14, blue: 0.24)
            )
        case .snow:
            return Palette(
                topDay: Color(red: 0.75, green: 0.82, blue: 0.95),
                bottomDay: Color(red: 0.9, green: 0.92, blue: 0.98),
                topNight: Color(red: 0.2, green: 0.25, blue: 0.4),
                bottomNight: Color(red: 0.3, green: 0.35, blue: 0.5)
            )
        case .thunderstorm:
            return Palette(
                topDay: Color(red: 0.2, green: 0.18, blue: 0.35),
                bottomDay: Color(red: 0.35, green: 0.3, blue: 0.5),
                topNight: Color(red: 0.05, green: 0.04, blue: 0.15),
                bottomNight: Color(red: 0.1, green: 0.08, blue: 0.22)
            )
        }
    }
}

// MARK: - Weather Gradient View

/// A full-bleed animated gradient background that shifts based on weather condition and time of day
struct WeatherGradientView: View {
    let condition: WeatherCondition
    var opacity: Double = 0.2
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isNight: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 6 || hour >= 20
    }
    
    private var gradientColors: [Color] {
        let palette = WeatherColors.palette(for: condition)
        let isDark = colorScheme == .dark || isNight
        
        if isDark {
            return [palette.topNight, palette.bottomNight]
        } else {
            return [palette.topDay, palette.bottomDay]
        }
    }
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(opacity)
        .animation(.easeInOut(duration: 5.0), value: condition.rawValue)
        .animation(.easeInOut(duration: 5.0), value: isNight)
    }
}
