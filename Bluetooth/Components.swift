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

// MARK: DraggableBar
/// A draggable bar control with a thumb indicator for RC car steering and throttle.
/// Supports both horizontal and vertical orientations.
struct DraggableBar: View {
    enum Orientation {
        case horizontal
        case vertical
    }
    
    var label: String
    var orientation: Orientation
    @Binding var value: CGFloat  // Normalized value from -1 to 1
    var color: Color
    var trackWidth: CGFloat
    var trackHeight: CGFloat
    
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let size = geo.size
                
                ZStack(alignment: orientation == .vertical ? .bottom : .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: trackWidth, height: trackHeight)
                    
                    // Center line indicator
                    if orientation == .horizontal {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: trackHeight - 8)
                            .position(x: trackWidth / 2, y: trackHeight / 2)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: trackWidth - 8, height: 2)
                            .position(x: trackWidth / 2, y: trackHeight / 2)
                    }
                    
                    // Draggable thumb
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 60, height: 60)
                            .shadow(color: color.opacity(0.4), radius: isDragging ? 12 : 6, x: 0, y: 2)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 60, height: 60)
                    }
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
                    .position(thumbPosition(in: size))
                }
                .frame(width: trackWidth, height: trackHeight)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            updateValue(from: gesture.location, in: size)
                        }
                        .onEnded { _ in
                            isDragging = false
                            // Auto-center when released
                            withAnimation(.easeOut(duration: 0.2)) {
                                value = 0
                            }
                        }
                )
            }
            .frame(width: trackWidth, height: trackHeight)
            
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }
    
    private func thumbPosition(in size: CGSize) -> CGPoint {
        if orientation == .horizontal {
            // Map value from -1...1 to 0...trackWidth
            let x = (value + 1) / 2 * trackWidth
            return CGPoint(x: x, y: trackHeight / 2)
        } else {
            // Map value from -1...1 to trackHeight...0 (inverted for up = positive)
            let y = (1 - ((value + 1) / 2)) * trackHeight
            return CGPoint(x: trackWidth / 2, y: y)
        }
    }
    
    private func updateValue(from location: CGPoint, in size: CGSize) {
        if orientation == .horizontal {
            // Map location.x from 0...trackWidth to -1...1
            let normalized = location.x / trackWidth
            value = min(max(normalized * 2 - 1, -1), 1)
        } else {
            // Map location.y from trackHeight...0 to -1...1 (inverted)
            let normalized = location.y / trackHeight
            value = min(max(1 - normalized * 2, -1), 1)
        }
    }
}
