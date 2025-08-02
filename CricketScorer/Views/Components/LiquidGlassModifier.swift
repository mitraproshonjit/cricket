import SwiftUI

// MARK: - Liquid Glass Design System

struct LiquidGlassModifier: ViewModifier {
    let intensity: CGFloat
    let cornerRadius: CGFloat
    let borderOpacity: CGFloat
    
    init(intensity: CGFloat = 0.8, cornerRadius: CGFloat = 20, borderOpacity: CGFloat = 0.2) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(intensity)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(borderOpacity),
                                        .clear,
                                        .white.opacity(borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct LiquidCardModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .modifier(LiquidGlassModifier(intensity: 0.9, cornerRadius: 16))
    }
}

struct EmotionalGradient {
    static let cricket = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.7, blue: 0.4),
            Color(red: 0.1, green: 0.8, blue: 0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunset = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.6, blue: 0.3),
            Color(red: 1.0, green: 0.4, blue: 0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let ocean = LinearGradient(
        colors: [
            Color(red: 0.3, green: 0.6, blue: 1.0),
            Color(red: 0.2, green: 0.5, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let teamA = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.5, blue: 1.0),
            Color(red: 0.3, green: 0.6, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let teamB = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.3, blue: 0.4),
            Color(red: 1.0, green: 0.4, blue: 0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neutral = LinearGradient(
        colors: [
            Color.gray.opacity(0.6),
            Color.gray.opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct LiquidButton: ButtonStyle {
    let gradient: LinearGradient
    let isDestructive: Bool
    
    init(gradient: LinearGradient = EmotionalGradient.cricket, isDestructive: Bool = false) {
        self.gradient = gradient
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive ? 
                          LinearGradient(colors: [.red.opacity(0.8), .red], startPoint: .top, endPoint: .bottom) :
                          gradient
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FloatingActionButton: View {
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(gradient)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Typography System

extension Font {
    static let cricketTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let cricketHeadline = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let cricketSubheadline = Font.system(size: 18, weight: .medium, design: .rounded)
    static let cricketBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let cricketCaption = Font.system(size: 14, weight: .medium, design: .rounded)
    static let cricketScore = Font.system(size: 48, weight: .heavy, design: .rounded)
}

// MARK: - View Extensions

extension View {
    func liquidGlass(intensity: CGFloat = 0.8, cornerRadius: CGFloat = 20, borderOpacity: CGFloat = 0.2) -> some View {
        self.modifier(LiquidGlassModifier(intensity: intensity, cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
    
    func liquidCard(isPressed: Bool = false) -> some View {
        self.modifier(LiquidCardModifier(isPressed: isPressed))
    }
    
    func cricketBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    func emotionalPulse(isActive: Bool = true) -> some View {
        self
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isActive
            )
    }
}

// MARK: - Haptic Feedback

class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}