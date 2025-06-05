import SwiftUI

struct WavyCircle: Shape {
    var frequency: Double = 8
    var amplitude: Double = 5
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        let points = 360
        
        for i in 0...points {
            let angle = Double(i) * .pi / 180
            let wave = sin(angle * frequency) * amplitude
            let r = radius + wave
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct PostureVisualizationView: View {
    let pitch: Double
    let postureQuality: HeadphoneMotionViewModel.PostureQuality
    
    @State private var animationAmount = 1.0
    @State private var phase: Double = 0
    
    var body: some View {
        ZStack {
            // Background wavy circle
            WavyCircle(frequency: 8, amplitude: 5)
                .stroke(
                    LinearGradient(
                        colors: [postureQuality.color.opacity(0.3), postureQuality.color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .background(
                    WavyCircle(frequency: 8, amplitude: 5)
                        .fill(Color(.systemBackground))
                )
                .rotationEffect(.degrees(phase))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: phase)
            
            // Posture indicator
            VStack(spacing: 20) {
                // Icon
                Image(systemName: postureQuality.icon)
                    .font(.system(size: 60))
                    .foregroundColor(postureQuality.color)
                    .scaleEffect(animationAmount)
                    .animation(
                        postureQuality == .poor ?
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                            .default,
                        value: animationAmount
                    )
                
                // Pitch value
                VStack(spacing: 4) {
                    Text(String(format: "%.1f°", pitch))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(postureQuality.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 220, height: 220)
        .onAppear {
            if postureQuality == .poor {
                animationAmount = 1.1
            }
            phase = 360
        }
        .onChange(of: postureQuality) { oldValue, newValue in
            animationAmount = newValue == .poor ? 1.1 : 1.0
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PostureVisualizationView(
            pitch: 0,
            postureQuality: .good
        )
        
        PostureVisualizationView(
            pitch: 15,
            postureQuality: .warning
        )
        
        PostureVisualizationView(
            pitch: 30,
            postureQuality: .poor
        )
    }
    .padding()
}
