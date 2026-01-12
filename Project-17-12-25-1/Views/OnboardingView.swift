import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var index = 0
    private let pages: [(title: String, subtitle: String)] = [
        ("Buy smarter, save more", "Celebrate every price drop with elegant insights."),
        ("Track price drops on everything you want", "Keep photos, targets, and savings in one premium place."),
        ("100% private and offline — your wishlist, your rules", "No accounts. No ads. Just your data on your device.")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            TabView(selection: $index) {
                ForEach(0..<pages.count, id: \.self) { idx in
                    VStack(spacing: 16) {
                        Text(pages[idx].title)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(pages[idx].subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            Spacer()
            Button(action: { advance() }) {
                Text(index == pages.count - 1 ? "Start" : "Next")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(ThemeManager.shared.currentTheme.gradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(radius: 12, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            ThemeManager.shared.currentTheme.gradient
                .opacity(0.15)
                .ignoresSafeArea()
        )
    }

    private func advance() {
        if index < pages.count - 1 {
            withAnimation { index += 1 }
        } else {
            onDone()
        }
    }
}

#Preview {
    OnboardingView { }
}

