import SwiftUI

// Basic static constants that don't change
struct Theme {
    static let offWhite = Color(UIColor.systemGray6)
    static let backgroundBase = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    
    // Glassmorphism background for modifiers
    static var glassMaterial: Material {
        .ultraThinMaterial
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("accentColorSelection") var accentColorSelection: Int = 0
    
    let accentColors: [Color] = [.blue, .purple, .pink, .green, .orange, .teal]
    
    var primaryAccent: Color {
        accentColors[safe: accentColorSelection] ?? .blue
    }
    
    var secondaryAccent: Color {
        // Just offset by 1 for a secondary color, wrapping around
        accentColors[safe: (accentColorSelection + 1) % accentColors.count] ?? .purple
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Custom ViewModifier for styling frosted rounded cards
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.glassMaterial)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCardStyle() -> some View {
        self.modifier(GlassCardModifier())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
