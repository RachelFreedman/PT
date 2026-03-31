import SwiftUI

enum Theme {
    // Primary gradient: purple → pink → orange
    static let purple = Color(red: 0xA4/255, green: 0x78/255, blue: 0xF1/255)
    static let pink   = Color(red: 0xF2/255, green: 0x43/255, blue: 0x89/255)
    static let orange = Color(red: 0xF0/255, green: 0xA1/255, blue: 0x3A/255)

    static let skipBlue  = Color(red: 0x61/255, green: 0xCE/255, blue: 0xF2/255)
    static let skipGreen = Color(red: 0x6B/255, green: 0x9E/255, blue: 0x6B/255)

    static let accent = purple

    static let gradient = LinearGradient(
        colors: [purple, pink, orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [purple.opacity(0.15), pink.opacity(0.08), orange.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Interpolate through the 3-stop gradient (0.0 = purple, 0.5 = pink, 1.0 = orange)
    private static let aR: Double = 0xA4/255, aG: Double = 0x78/255, aB: Double = 0xF1/255
    private static let bR: Double = 0xF2/255, bG: Double = 0x43/255, bB: Double = 0x89/255
    private static let cR: Double = 0xF0/255, cG: Double = 0xA1/255, cB: Double = 0x3A/255

    static func gradientColor(at t: Double) -> Color {
        let t = max(0, min(1, t))
        let r, g, b: Double
        if t <= 0.5 {
            let s = t / 0.5
            r = aR + (bR - aR) * s
            g = aG + (bG - aG) * s
            b = aB + (bB - aB) * s
        } else {
            let s = (t - 0.5) / 0.5
            r = bR + (cR - bR) * s
            g = bG + (cG - bG) * s
            b = bB + (cB - bB) * s
        }
        return Color(red: r, green: g, blue: b)
    }

    /// Color for a batch level (1–16) on the gradient
    static func batchColor(for level: Int) -> Color {
        gradientColor(at: Double(level - 1) / 15.0)
    }
}
