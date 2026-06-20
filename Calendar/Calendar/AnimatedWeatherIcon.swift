import SwiftUI

/// Apple Weather-style animated weather icons using SwiftUI Canvas + TimelineView
struct AnimatedWeatherIcon: View {
    let condition: WeatherCondition
    var size: CGFloat = 80
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        if reduceMotion {
            // Static fallback
            Image(systemName: condition.sfSymbolName)
                .font(.system(size: size * 0.6))
                .foregroundStyle(iconGradient)
                .frame(width: size, height: size)
                .accessibilityLabel(condition.rawValue)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, canvasSize in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    drawWeatherIcon(context: context, size: canvasSize, time: time)
                }
                .frame(width: size, height: size)
            }
            .accessibilityLabel(condition.rawValue)
        }
    }
    
    // MARK: - Drawing
    
    private func drawWeatherIcon(context: GraphicsContext, size: CGSize, time: Double) {
        switch condition {
        case .clear:
            drawSun(context: context, size: size, time: time)
        case .partlyCloudy:
            drawPartlyCloudy(context: context, size: size, time: time)
        case .cloudy:
            drawCloudy(context: context, size: size, time: time)
        case .fog:
            drawFog(context: context, size: size, time: time)
        case .drizzle, .freezingDrizzle:
            drawRain(context: context, size: size, time: time, intensity: 0.4)
        case .rain, .freezingRain:
            drawRain(context: context, size: size, time: time, intensity: 0.7)
        case .heavyRain:
            drawRain(context: context, size: size, time: time, intensity: 1.0)
        case .snow:
            drawSnow(context: context, size: size, time: time)
        case .thunderstorm:
            drawThunderstorm(context: context, size: size, time: time)
        }
    }
    
    // MARK: - Sun
    
    private func drawSun(context: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = size.width * 0.18
        let rayLength = size.width * 0.12
        let pulseScale = 1.0 + sin(time * 1.5) * 0.06
        
        // Draw rays
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4.0 + time * 0.15
            let innerR = radius * 1.4 * pulseScale
            let outerR = (radius * 1.4 + rayLength) * pulseScale
            
            let start = CGPoint(
                x: center.x + cos(angle) * innerR,
                y: center.y + sin(angle) * innerR
            )
            let end = CGPoint(
                x: center.x + cos(angle) * outerR,
                y: center.y + sin(angle) * outerR
            )
            
            var rayPath = Path()
            rayPath.move(to: start)
            rayPath.addLine(to: end)
            
            context.stroke(rayPath, with: .color(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.8)), lineWidth: size.width * 0.03)
        }
        
        // Draw sun circle
        let sunRect = CGRect(
            x: center.x - radius * pulseScale,
            y: center.y - radius * pulseScale,
            width: radius * 2 * pulseScale,
            height: radius * 2 * pulseScale
        )
        
        let gradient = Gradient(colors: [
            Color(red: 1.0, green: 0.85, blue: 0.2),
            Color(red: 1.0, green: 0.65, blue: 0.1)
        ])
        
        context.fill(
            Path(ellipseIn: sunRect),
            with: .linearGradient(gradient, startPoint: CGPoint(x: sunRect.minX, y: sunRect.minY), endPoint: CGPoint(x: sunRect.maxX, y: sunRect.maxY))
        )
    }
    
    // MARK: - Cloud Helper
    
    private func drawCloud(context: GraphicsContext, center: CGPoint, scale: CGFloat, color: Color, opacity: Double = 1.0) {
        var cloud = Path()
        let w = scale
        let h = scale * 0.55
        
        // Cloud shape using arcs
        cloud.addEllipse(in: CGRect(x: center.x - w * 0.5, y: center.y - h * 0.2, width: w, height: h))
        cloud.addEllipse(in: CGRect(x: center.x - w * 0.35, y: center.y - h * 0.6, width: w * 0.6, height: h * 0.7))
        cloud.addEllipse(in: CGRect(x: center.x - w * 0.05, y: center.y - h * 0.7, width: w * 0.5, height: h * 0.7))
        
        context.fill(cloud, with: .color(color.opacity(opacity)))
    }
    
    // MARK: - Partly Cloudy
    
    private func drawPartlyCloudy(context: GraphicsContext, size: CGSize, time: Double) {
        // Draw small sun in top-right
        let sunCenter = CGPoint(x: size.width * 0.65, y: size.height * 0.3)
        let sunRadius = size.width * 0.12
        let pulseScale = 1.0 + sin(time * 1.5) * 0.04
        
        let sunRect = CGRect(
            x: sunCenter.x - sunRadius * pulseScale,
            y: sunCenter.y - sunRadius * pulseScale,
            width: sunRadius * 2 * pulseScale,
            height: sunRadius * 2 * pulseScale
        )
        context.fill(Path(ellipseIn: sunRect), with: .color(Color(red: 1.0, green: 0.8, blue: 0.2)))
        
        // Drifting cloud
        let cloudOffset = sin(time * 0.4) * size.width * 0.03
        let cloudCenter = CGPoint(x: size.width * 0.45 + cloudOffset, y: size.height * 0.55)
        drawCloud(context: context, center: cloudCenter, scale: size.width * 0.6, color: .white, opacity: 0.95)
    }
    
    // MARK: - Cloudy
    
    private func drawCloudy(context: GraphicsContext, size: CGSize, time: Double) {
        let drift1 = sin(time * 0.3) * size.width * 0.02
        let drift2 = sin(time * 0.25 + 1.0) * size.width * 0.025
        
        // Back cloud (darker)
        drawCloud(context: context, center: CGPoint(x: size.width * 0.55 + drift2, y: size.height * 0.4), scale: size.width * 0.5, color: Color(white: 0.75))
        // Front cloud
        drawCloud(context: context, center: CGPoint(x: size.width * 0.42 + drift1, y: size.height * 0.55), scale: size.width * 0.6, color: Color(white: 0.88))
    }
    
    // MARK: - Rain
    
    private func drawRain(context: GraphicsContext, size: CGSize, time: Double, intensity: Double) {
        // Cloud
        let cloudCenter = CGPoint(x: size.width * 0.45, y: size.height * 0.32)
        drawCloud(context: context, center: cloudCenter, scale: size.width * 0.6, color: Color(white: 0.7))
        
        // Raindrops
        let dropCount = Int(3 + intensity * 4)
        for i in 0..<dropCount {
            let xBase = size.width * (0.25 + Double(i) / Double(dropCount) * 0.5)
            let phase = time * (2.0 + intensity) + Double(i) * 1.3
            let yProgress = (phase.truncatingRemainder(dividingBy: 1.5)) / 1.5
            let y = size.height * 0.5 + yProgress * size.height * 0.35
            let dropOpacity = 1.0 - yProgress * 0.6
            
            var drop = Path()
            drop.move(to: CGPoint(x: xBase, y: y))
            drop.addLine(to: CGPoint(x: xBase, y: y + size.height * 0.06))
            
            context.stroke(drop, with: .color(Color(red: 0.4, green: 0.65, blue: 1.0).opacity(dropOpacity * intensity)), lineWidth: size.width * 0.02)
        }
    }
    
    // MARK: - Snow
    
    private func drawSnow(context: GraphicsContext, size: CGSize, time: Double) {
        // Cloud
        let cloudCenter = CGPoint(x: size.width * 0.45, y: size.height * 0.3)
        drawCloud(context: context, center: cloudCenter, scale: size.width * 0.6, color: Color(white: 0.82))
        
        // Snowflakes
        for i in 0..<6 {
            let xBase = size.width * (0.2 + Double(i) / 6.0 * 0.6)
            let phase = time * 0.8 + Double(i) * 1.1
            let yProgress = (phase.truncatingRemainder(dividingBy: 2.5)) / 2.5
            let y = size.height * 0.48 + yProgress * size.height * 0.4
            let xDrift = sin(phase * 2.0) * size.width * 0.03
            let flakeOpacity = 1.0 - yProgress * 0.5
            
            let flakeSize = size.width * 0.035
            let flakeRect = CGRect(x: xBase + xDrift - flakeSize / 2, y: y - flakeSize / 2, width: flakeSize, height: flakeSize)
            context.fill(Path(ellipseIn: flakeRect), with: .color(Color.white.opacity(flakeOpacity * 0.9)))
        }
    }
    
    // MARK: - Fog
    
    private func drawFog(context: GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<4 {
            let y = size.height * (0.3 + Double(i) * 0.15)
            let drift = sin(time * 0.3 + Double(i) * 0.8) * size.width * 0.05
            let lineWidth = size.width * (0.55 - Double(i) * 0.05)
            let xCenter = size.width * 0.5 + drift
            
            var line = Path()
            line.move(to: CGPoint(x: xCenter - lineWidth / 2, y: y))
            line.addLine(to: CGPoint(x: xCenter + lineWidth / 2, y: y))
            
            let opacity = 0.4 - Double(i) * 0.06
            context.stroke(line, with: .color(Color(white: 0.7).opacity(opacity)), style: StrokeStyle(lineWidth: size.height * 0.04, lineCap: .round))
        }
    }
    
    // MARK: - Thunderstorm
    
    private func drawThunderstorm(context: GraphicsContext, size: CGSize, time: Double) {
        // Dark cloud
        let cloudCenter = CGPoint(x: size.width * 0.45, y: size.height * 0.3)
        drawCloud(context: context, center: cloudCenter, scale: size.width * 0.6, color: Color(white: 0.45))
        
        // Lightning bolt
        let flashPhase = time.truncatingRemainder(dividingBy: 3.0)
        let flashOpacity = flashPhase < 0.15 ? 1.0 : (flashPhase < 0.3 ? 0.3 : 0.0)
        
        if flashOpacity > 0 {
            var bolt = Path()
            bolt.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.45))
            bolt.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.6))
            bolt.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.6))
            bolt.addLine(to: CGPoint(x: size.width * 0.44, y: size.height * 0.8))
            
            context.stroke(bolt, with: .color(Color(red: 1.0, green: 0.9, blue: 0.3).opacity(flashOpacity)), lineWidth: size.width * 0.03)
        }
        
        // Rain
        drawRain(context: context, size: size, time: time, intensity: 0.8)
    }
    
    // MARK: - Icon Gradient (for static fallback)
    
    private var iconGradient: some ShapeStyle {
        switch condition {
        case .clear:
            return AnyShapeStyle(Color(red: 1.0, green: 0.8, blue: 0.2))
        case .snow:
            return AnyShapeStyle(Color(red: 0.7, green: 0.85, blue: 1.0))
        case .thunderstorm:
            return AnyShapeStyle(Color(red: 0.5, green: 0.4, blue: 0.8))
        default:
            return AnyShapeStyle(Color(red: 0.6, green: 0.7, blue: 0.85))
        }
    }
}
