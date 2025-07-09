import SwiftUI

extension View {
    func scaleEffectOnTap() -> some View {
        modifier(ScaleEffectOnTap())
    }
    
    func adaptiveFrame() -> some View {
        modifier(AdaptiveFrameModifier())
    }
}

// MARK: - Device Detection
struct DeviceInfo {
    static var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var isLargeScreen: Bool {
        return screenWidth > 390 // iPhone 14 Pro Max and larger
    }
    
    static var isSmallScreen: Bool {
        return screenWidth <= 375 // iPhone SE and smaller
    }
}

// MARK: - Color Extensions for Dark Mode Support
extension Color {
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let mainBackground = Color(UIColor.systemBackground)
    static let surfaceBackground = Color(UIColor.systemGray6)
    static let placeholderText = Color(UIColor.placeholderText)
    static let separatorColor = Color(UIColor.separator)
    
    // Crypto specific colors
    static let cryptoGreen = Color(red: 0.0, green: 0.7, blue: 0.2)
    static let cryptoRed = Color(red: 0.8, green: 0.0, blue: 0.0)
    static let cryptoBlue = Color(red: 0.0, green: 0.5, blue: 1.0)
}

struct ScaleEffectOnTap: ViewModifier {
    @State private var pressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1)
            .onLongPressGesture(minimumDuration: 0.01, pressing: { isPressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressed = isPressing
                }
            }, perform: {})
    }
}

struct AdaptiveFrameModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: DeviceInfo.isIPad ? 800 : .infinity)
    }
}

extension Double {
    func toPercentage() -> String {
        return String(format: "%.2f%%", self)
    }
    
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    func cleanAmountString() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

extension Date {
    func toShortString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
} 