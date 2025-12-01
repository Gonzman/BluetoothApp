import SwiftUI

// MARK: VerticalBar
struct VerticalBar: View {
    var label: String
    var fillHeight: CGFloat
    var height: CGFloat? = nil
    var width: CGFloat? = nil
    var color: Color
    var mappedFromY: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let barWidth = width ?? geo.size.width
            let barHeight = height ?? geo.size.height
            let resolvedFill: CGFloat = {
                if let y = mappedFromY {
                    let clamped = max(-200, min(200, -y))
                    let normalized = (clamped + 200) / 400
                    return normalized * barHeight
                } else {
                    return fillHeight
                }
            }()
            let clampedFill = min(max(resolvedFill, 0), barHeight)
            let fillPercentage = clampedFill / barHeight
            
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: barWidth, height: barHeight)
                        .foregroundColor(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: barWidth, height: clampedFill)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .animation(.easeOut(duration: 0.1), value: clampedFill)
                    
                    // Level indicator lines
                    VStack(spacing: barHeight / 5 - 1) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: barWidth - 8, height: 1)
                        }
                    }
                    .padding(.bottom, barHeight / 10)
                }
                .shadow(color: color.opacity(fillPercentage > 0.5 ? 0.3 : 0), radius: 8, x: 0, y: 0)
                
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: barWidth, height: barHeight, alignment: .bottom)
        }
    }
}

// MARK: BoostButton
/// A button that allows boosting with press-and-hold gesture.
/// The parent view can observe the boosting state via the `isBoosting` binding.
struct BoostButton: View {
    @Binding var boostLevel: CGFloat
    @Binding var isBoosting: Bool

    var enabled: Bool
    var maxLevel: CGFloat

    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    enabled
                    ? LinearGradient(
                        colors: isBoosting 
                            ? [Color(red: 1.0, green: 0.3, blue: 0.2), Color(red: 0.9, green: 0.1, blue: 0.1)]
                            : [Color(red: 0.95, green: 0.35, blue: 0.25), Color(red: 0.85, green: 0.2, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: enabled && isBoosting ? Color.red.opacity(0.5) : .clear, radius: 12, x: 0, y: 4)
            
            // Inner highlight
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(enabled ? 0.2 : 0.1), lineWidth: 1)
                .padding(1)
            
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolEffect(.pulse, isActive: isBoosting)
                Text("BOOST")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundColor(.white)
            .opacity(enabled ? 1.0 : 0.6)
        }
        .scaleEffect(isBoosting ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isBoosting)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if enabled {
                        startPress()
                    }
                }
                .onEnded { _ in
                    endPress()
                }
        )
        .onDisappear {
            endPress()
        }
    }

    private func startPress() {
        guard enabled else { return }
        if isBoosting { return }
        isBoosting = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.linear(duration: 0.03)) {
                boostLevel = max(0, boostLevel - 0.8)
            }
        }
    }

    private func endPress() {
        if !isBoosting { return }
        isBoosting = false
        timer?.invalidate()
        timer = nil
    }
}
