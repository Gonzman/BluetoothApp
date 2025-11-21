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
            VStack {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: barWidth, height: barHeight)
                        .foregroundColor(.gray.opacity(0.28))
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: barWidth, height: clampedFill)
                        .foregroundColor(color)
                        .animation(.linear(duration: 0.08), value: clampedFill)
                }
                Text(label)
                    .font(.caption)
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
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(
                    enabled
                    ? (isBoosting ? Color.red : Color.red.opacity(0.9))
                    : Color.gray
                )
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                Text("Boost")
                    .bold()
            }
            .foregroundColor(.white)
        }
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
