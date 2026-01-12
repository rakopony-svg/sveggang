import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    

    var body: some View {
        ZStack {
            ThemeManager.shared.currentTheme.gradient
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }
}


