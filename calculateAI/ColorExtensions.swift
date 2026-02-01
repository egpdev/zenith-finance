import SwiftUI

extension Color {
    static let zenithBlack = Color(red: 0.05, green: 0.05, blue: 0.05) // Deep Obsidian Black
    static let zenithCharcoal = Color(red: 0.12, green: 0.12, blue: 0.14) // Dark Charcoal
    static let neonTurquoise = Color(red: 0.0, green: 0.9, blue: 0.85) // Glowing Turquoise
    static let mintGreen = Color(red: 0.2, green: 1.0, blue: 0.6) // Vibrant Mint
    static let glassBorder = Color.white.opacity(0.15)
}

struct ZenithTheme {
    static let background = Color.zenithBlack
    static let cardBackground = Color.zenithCharcoal.opacity(0.6)
    static let accentMain = Color.neonTurquoise
    static let accentSecondary = Color.mintGreen
}
