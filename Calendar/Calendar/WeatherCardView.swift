import SwiftUI

/// A frosted-glass weather card showing current conditions, temperature, and precipitation
struct WeatherCardView: View {
    let forecast: DailyForecast
    var currentTemp: Double?
    var isCompact: Bool = false
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var condition: WeatherCondition {
        WeatherManager.condition(for: forecast.weatherCode)
    }
    
    var body: some View {
        HStack(spacing: isCompact ? 12 : 16) {
            // Animated weather icon
            AnimatedWeatherIcon(
                condition: condition,
                size: isCompact ? 44 : 72
            )
            
            VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                // Condition label
                Text(condition.rawValue)
                    .font(isCompact ?
                        .system(size: 13, weight: .medium, design: .rounded) :
                        .system(size: 15, weight: .semibold, design: .rounded)
                    )
                    .foregroundColor(.secondary)
                
                // Temperature
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let temp = currentTemp {
                        Text("\(Int(temp.rounded()))°")
                            .font(.system(size: isCompact ? 28 : 42, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("\(Int(forecast.tempMax.rounded()))°")
                            .font(.system(size: isCompact ? 28 : 42, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                if !isCompact {
                    // Feels like + high/low
                    HStack(spacing: 12) {
                        Label("Feels \(Int(forecast.feelsLikeMax.rounded()))°", systemImage: "thermometer.medium")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red.opacity(0.7))
                            Text("\(Int(forecast.tempMax.rounded()))°")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue.opacity(0.7))
                            Text("\(Int(forecast.tempMin.rounded()))°")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Precipitation indicator
            if forecast.precipProbabilityMax > 0 {
                VStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: isCompact ? 14 : 18))
                        .foregroundColor(.blue.opacity(0.7))
                    Text("\(forecast.precipProbabilityMax)%")
                        .font(.system(size: isCompact ? 11 : 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue.opacity(0.7))
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            ZStack {
                WeatherGradientView(condition: condition, opacity: 0.12)
                    .clipShape(RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous))
                
                RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
