import SwiftUI

// MARK: VerticalBar
struct VerticalBar: View {
    var label: String
    var fillHeight: CGFloat
    var maxHeight: CGFloat
    var color: Color

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 40, height: maxHeight)
                    .foregroundColor(.gray.opacity(0.28))
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 40, height: min(max(fillHeight, 0), maxHeight))
                    .foregroundColor(color)
                    .animation(.linear(duration: 0.08), value: fillHeight)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: YVerticalBar
struct YVerticalBar: View {
    var label: String
    var yValue: CGFloat
    var maxHeight: CGFloat
    var color: Color

    var mappedHeight: CGFloat {
        let clamped = max(-200, min(200, -yValue))
        let normalized = (clamped + 200) / 400
        return normalized * maxHeight
    }

    var body: some View {
        VerticalBar(label: label, fillHeight: mappedHeight, maxHeight: maxHeight, color: color)
    }
}

struct HorizontalMover: View {
    var value: CGFloat
    var rectWidth: CGFloat

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width
            let available = max(usable - rectWidth, 0)
            let clamped = max(-200, min(200, value))
            let normalized = (clamped + 200) / 400
            let xOffset = normalized * available
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.gray.opacity(0.18))
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: rectWidth, height: 32)
                    .foregroundColor(.green)
                    .offset(x: xOffset)
                    .animation(.easeOut(duration: 0.12), value: clamped)
            }
            .frame(height: 36)
        }
        .frame(height: 36)
    }
}

// MARK: BoostButton
struct BoostButton: View {
    @Binding var boostLevel: CGFloat
    
    @State private var pressing = false
    @State private var timer: Timer?

    var maxLevel: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(pressing ? Color.red : Color.red.opacity(0.9))
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                Text("Boost")
                    .bold()
            }
            .foregroundColor(.white)
        }
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in startPress() }
            .onEnded { _ in endPress() })
        .onDisappear { endPress() }
    }

    func startPress() {
        if pressing { return }
        pressing = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.linear(duration: 0.03)) {
                boostLevel = max(0, boostLevel - 0.8)
            }
        }
    }

    func endPress() {
        pressing = false
        timer?.invalidate()
        timer = nil
    }
}
