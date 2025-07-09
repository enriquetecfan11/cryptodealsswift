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

// MARK: - Loading Components
struct LoadingOverlay: View {
    let message: String
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cryptoBlue))
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .frame(maxWidth: 280)
            }
        }
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.cryptoRed)
            
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Intentar nuevamente")
                }
                .font(.callout.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.cryptoBlue)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
}

struct SkeletonLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding()
    }
}

struct SkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.surfaceBackground)
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)
            
            VStack(alignment: .leading, spacing: 6) {
                // Name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceBackground)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer(isAnimating: isAnimating)
                
                // Price skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceBackground)
                    .frame(height: 12)
                    .frame(maxWidth: 120)
                    .shimmer(isAnimating: isAnimating)
            }
            
            Spacer()
            
            // Change skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.surfaceBackground)
                .frame(width: 60, height: 14)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct DetailLoadingView: View {
    let cryptoName: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Header loading
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.surfaceBackground)
                    .frame(width: 60, height: 60)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(cryptoName)
                        .font(.title2.bold())
                        .foregroundColor(.primaryText)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceBackground)
                        .frame(height: 16)
                        .frame(maxWidth: 80)
                        .shimmer()
                }
                
                Spacer()
            }
            
            // Price loading
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surfaceBackground)
                    .frame(height: 48)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.surfaceBackground)
                    .frame(height: 24)
                    .frame(maxWidth: 120)
                    .shimmer()
            }
            
            // Stats loading
            VStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceBackground)
                            .frame(height: 16)
                            .frame(maxWidth: 140)
                            .shimmer()
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceBackground)
                            .frame(height: 16)
                            .frame(maxWidth: 100)
                            .shimmer()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct LoadingStateView: View {
    let state: LoadingState
    let retryAction: () -> Void
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cryptoBlue))
                        .scaleEffect(1.2)
                    
                    Text("Cargando...")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                .padding(.vertical, 40)
            case .success:
                EmptyView()
            case .failure(let message):
                ErrorStateView(
                    title: "Error de carga",
                    message: message,
                    retryAction: retryAction
                )
                .padding()
            }
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: isAnimating ? 300 : -300)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmer(isAnimating: Bool = true) -> some View {
        modifier(ShimmerModifier())
    }
} 