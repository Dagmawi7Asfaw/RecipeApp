import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -30
    @State private var titleOffset: CGFloat = 40
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var particlesVisible: Bool = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    
    let onFinished: () -> Void
    
    // Food emoji particles
    private let foodEmojis = ["🍕", "🍜", "🥘", "🍣", "🌮", "🥗", "🍰", "🧁", "🍝", "🥙", "🍛", "🥐"]
    
    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.22),
                    Color(red: 0.08, green: 0.02, blue: 0.18),
                    Color(red: 0.05, green: 0.01, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle radial glow behind logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .blur(radius: 40)
            
            // Floating food emoji particles
            if particlesVisible {
                ForEach(0..<12, id: \.self) { index in
                    FloatingParticle(emoji: foodEmojis[index], index: index)
                }
            }
            
            // Decorative spinning ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.purple, .pink, .orange, .yellow, .pink, .purple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8])
                )
                .frame(width: 200, height: 200)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .rotationEffect(.degrees(ringRotation))
            
            // Second ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.pink.opacity(0.5), .orange.opacity(0.3), .purple.opacity(0.5)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 12])
                )
                .frame(width: 260, height: 260)
                .scaleEffect(ringScale)
                .opacity(ringOpacity * 0.6)
                .rotationEffect(.degrees(-ringRotation * 0.7))
            
            VStack(spacing: 20) {
                // App Logo
                ZStack {
                    // Glow behind logo
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 130, height: 130)
                        .blur(radius: 25)
                    
                    Image("RecipeApp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .purple.opacity(0.5), radius: 20, y: 8)
                        .overlay {
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                )
                        }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .rotationEffect(.degrees(logoRotation))
                
                // App Title
                VStack(spacing: 8) {
                    Text("RecipeApp")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("7 Continents Culinary Suite")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                
                // Loading dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .scaleEffect(particlesVisible ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: particlesVisible
                            )
                    }
                }
                .padding(.top, 30)
                .opacity(subtitleOpacity)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear {
            runAnimation()
        }
    }
    
    private func runAnimation() {
        // Phase 1: Logo entrance (0s - 0.7s)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Phase 2: Rings appear (0.3s)
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            ringScale = 1.0
            ringOpacity = 0.7
        }
        
        // Rings continuously rotate
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false).delay(0.3)) {
            ringRotation = 360
        }
        
        // Phase 3: Title slides up (0.5s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Phase 4: Subtitle fades in (0.8s)
        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            subtitleOpacity = 1.0
        }
        
        // Phase 5: Particles appear (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particlesVisible = true
        }
        
        // Phase 6: Shimmer across logo (1.0s)
        withAnimation(.easeInOut(duration: 0.8).delay(1.0)) {
            shimmerOffset = 200
        }
        
        // Phase 7: Exit transition (2.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.easeIn(duration: 0.3)) {
                exitScale = 1.15
                exitOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onFinished()
            }
        }
    }
}

// MARK: - Floating Particle

struct FloatingParticle: View {
    let emoji: String
    let index: Int
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    
    var body: some View {
        Text(emoji)
            .font(.system(size: CGFloat.random(in: 18...30)))
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
                let radius: CGFloat = CGFloat.random(in: 160...300)
                let targetX = cos(angle) * radius
                let targetY = sin(angle) * radius
                
                withAnimation(
                    .easeOut(duration: Double.random(in: 1.2...2.0))
                    .delay(Double.random(in: 0.1...0.6))
                ) {
                    offset = CGSize(width: targetX, height: targetY)
                    opacity = Double.random(in: 0.3...0.7)
                    scale = CGFloat.random(in: 0.6...1.0)
                }
                
                // Gentle floating drift
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2.0...3.5))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0.5...1.5))
                ) {
                    offset = CGSize(
                        width: targetX + CGFloat.random(in: -20...20),
                        height: targetY + CGFloat.random(in: -20...20)
                    )
                }
            }
    }
}
