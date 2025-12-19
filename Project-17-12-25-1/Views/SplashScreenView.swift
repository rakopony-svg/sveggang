import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            ThemeManager.shared.currentTheme.gradient
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(ThemeManager.shared.currentTheme.accent)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 12)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: scale)
                    .animation(.easeIn(duration: 0.6), value: opacity)

                Text("Price Drop Wishlist Manager")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(.primary)
                    .opacity(opacity)
                    .animation(.easeIn(duration: 0.6), value: opacity)
            }
        }
        .onAppear {
            withAnimation {
                scale = 1.0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
}

