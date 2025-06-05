import SwiftUI

struct PostureVisualizationView: View {
    let pitch: Double
    let postureQuality: HeadphoneMotionViewModel.PostureQuality
    
    @State private var animationAmount = 1.0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [postureQuality.color.opacity(0.3), postureQuality.color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                )
            
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
            
            // Rotation indicator
            Image(systemName: "person.fill")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(pitch))
                .offset(y: -90)
        }
        .frame(width: 220, height: 220)
        .onAppear {
            if postureQuality == .poor {
                animationAmount = 1.1
            }
        }
        .onChange(of: postureQuality) { oldValue, newValue in
            animationAmount = newValue == .poor ? 1.1 : 1.0
        }
    }
}
