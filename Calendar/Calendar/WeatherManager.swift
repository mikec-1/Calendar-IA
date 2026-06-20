import Foundation
import CoreLocation

// MARK: - Weather Data Models

/// Hourly forecast data point from Open-Meteo
struct HourlyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let weatherCode: Int
    let precipProbability: Int
}

/// Daily forecast data point from Open-Meteo
struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let tempMax: Double
    let tempMin: Double
    let feelsLikeMax: Double
    let feelsLikeMin: Double
    let precipProbabilityMax: Int
}

/// Top-level weather data container
struct WeatherData {
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let fetchedAt: Date
    
    /// Returns the daily forecast for a specific date
    func dailyForecast(for date: Date) -> DailyForecast? {
        daily.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    /// Returns hourly forecasts for a specific date
    func hourlyForecasts(for date: Date) -> [HourlyForecast] {
        hourly.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    /// Returns the current hour's forecast (closest to now)
    func currentHourForecast() -> HourlyForecast? {
        let now = Date()
        return hourly.min(by: { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) })
    }
}

// MARK: - Weather Condition

/// Semantic weather condition derived from WMO codes
enum WeatherCondition: String {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case fog = "Fog"
    case drizzle = "Drizzle"
    case freezingDrizzle = "Freezing Drizzle"
    case rain = "Rain"
    case freezingRain = "Freezing Rain"
    case snow = "Snow"
    case heavyRain = "Heavy Rain"
    case thunderstorm = "Thunderstorm"
    
    var sfSymbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .freezingDrizzle: return "cloud.sleet.fill"
        case .rain: return "cloud.rain.fill"
        case .freezingRain: return "cloud.sleet.fill"
        case .snow: return "cloud.snow.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        }
    }
}

// MARK: - Weather Manager

class WeatherManager {
    static let shared = WeatherManager()
    
    /// Fetches complete weather data (hourly + daily) from Open-Meteo
    func fetchWeatherData(latitude: Double, longitude: Double) async throws -> WeatherData {
        let hourlyParams = "temperature_2m,weather_code,precipitation_probability"
        let dailyParams = "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max"
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&hourly=\(hourlyParams)&daily=\(dailyParams)&timezone=auto&forecast_days=10"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        let hourly = parseHourly(json)
        let daily = parseDaily(json)
        
        return WeatherData(hourly: hourly, daily: daily, fetchedAt: Date())
    }
    
    // MARK: - Parsing
    
    private func parseHourly(_ json: [String: Any]) -> [HourlyForecast] {
        guard let hourlyDict = json["hourly"] as? [String: Any],
              let times = hourlyDict["time"] as? [String],
              let temps = hourlyDict["temperature_2m"] as? [Double],
              let codes = hourlyDict["weather_code"] as? [Int],
              let precips = hourlyDict["precipitation_probability"] as? [Int] else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime]
        
        var forecasts: [HourlyForecast] = []
        for i in 0..<min(times.count, min(temps.count, min(codes.count, precips.count))) {
            if let date = formatter.date(from: times[i]) {
                forecasts.append(HourlyForecast(
                    date: date,
                    temperature: temps[i],
                    weatherCode: codes[i],
                    precipProbability: precips[i]
                ))
            }
        }
        return forecasts
    }
    
    private func parseDaily(_ json: [String: Any]) -> [DailyForecast] {
        guard let dailyDict = json["daily"] as? [String: Any],
              let times = dailyDict["time"] as? [String],
              let codes = dailyDict["weather_code"] as? [Int],
              let maxTemps = dailyDict["temperature_2m_max"] as? [Double],
              let minTemps = dailyDict["temperature_2m_min"] as? [Double],
              let feelsMax = dailyDict["apparent_temperature_max"] as? [Double],
              let feelsMin = dailyDict["apparent_temperature_min"] as? [Double],
              let precipMax = dailyDict["precipitation_probability_max"] as? [Int] else {
            return []
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        var forecasts: [DailyForecast] = []
        let count = min(times.count, min(codes.count, min(maxTemps.count, min(minTemps.count, min(feelsMax.count, min(feelsMin.count, precipMax.count))))))
        
        for i in 0..<count {
            if let date = dateFormatter.date(from: times[i]) {
                forecasts.append(DailyForecast(
                    date: date,
                    weatherCode: codes[i],
                    tempMax: maxTemps[i],
                    tempMin: minTemps[i],
                    feelsLikeMax: feelsMax[i],
                    feelsLikeMin: feelsMin[i],
                    precipProbabilityMax: precipMax[i]
                ))
            }
        }
        return forecasts
    }
    
    // MARK: - Condition Mapping
    
    /// Maps WMO weather code to a semantic WeatherCondition
    static func condition(for wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0: return .clear
        case 1, 2, 3: return .partlyCloudy
        case 45, 48: return .fog
        case 51, 53, 55: return .drizzle
        case 56, 57: return .freezingDrizzle
        case 61, 63, 65: return .rain
        case 66, 67: return .freezingRain
        case 71, 73, 75, 77: return .snow
        case 80, 81, 82: return .heavyRain
        case 95, 96, 99: return .thunderstorm
        default: return .cloudy
        }
    }
    
    /// Returns the SF Symbol name for a WMO code
    func sfSymbolName(for wmoCode: Int) -> String {
        return WeatherManager.condition(for: wmoCode).sfSymbolName
    }
}
