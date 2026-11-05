import SwiftUI
import AudioToolbox

private enum TimerPhase {
    case idle, running, paused, finished
}

struct ContentView: View {
    @State private var setMinutes = 1
    @State private var setSeconds = 0
    @State private var phase: TimerPhase = .idle
    @State private var total: TimeInterval = 60
    @State private var remaining: TimeInterval = 60
    @State private var endDate = Date()
    @State private var burst = false

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let confettiColors: [Color] = [.orange, .pink, .yellow, .mint, .cyan, .purple]

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    phase == .finished ? Color.orange.opacity(0.18) : Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: phase)

            VStack(spacing: 28) {
                Spacer(minLength: 0)
                dial
                pickers
                Spacer(minLength: 0)
                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onReceive(ticker) { _ in tick() }
        .onChange(of: setMinutes) { _ in pickersChanged() }
        .onChange(of: setSeconds) { _ in pickersChanged() }
        .onChange(of: phase) { newValue in
            UIApplication.shared.isIdleTimerDisabled = (newValue == .running)
        }
    }

    // MARK: - Dial

    private var dial: some View {
        ZStack {
            if phase == .finished {
                burstView
            }

            Circle()
                .stroke(
                    phase == .finished ? Color.orange.opacity(0.35) : Color.primary.opacity(0.08),
                    lineWidth: 18
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(timeString)
                    .font(.system(size: 76, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(phase == .finished ? .orange : .secondary)
            }
            .padding(.horizontal, 28)
            .scaleEffect(phase == .finished && burst ? 1.1 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.35), value: burst)
        }
        .frame(maxWidth: 320)
        .aspectRatio(1, contentMode: .fit)
    }

    private var burstView: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.orange, lineWidth: 5)
                    .scaleEffect(burst ? 1.9 : 0.9)
                    .opacity(burst ? 0 : 0.9)
                    .animation(.easeOut(duration: 1.4).delay(Double(i) * 0.25), value: burst)
            }
            ForEach(0..<16, id: \.self) { i in
                particle(i)
            }
        }
    }

    private func particle(_ i: Int) -> some View {
        let angle = Double(i) / 16.0 * 2 * Double.pi
        let distance: CGFloat = 170
        return Circle()
            .fill(confettiColors[i % confettiColors.count])
            .frame(width: 12, height: 12)
            .offset(
                x: burst ? CGFloat(cos(angle)) * distance : 0,
                y: burst ? CGFloat(sin(angle)) * distance : 0
            )
            .scaleEffect(burst ? 0.3 : 1)
            .opacity(burst ? 0 : 1)
            .animation(.easeOut(duration: 1.2).delay(Double(i % 4) * 0.05), value: burst)
    }

    // MARK: - Pickers

    private var pickers: some View {
        HStack(spacing: 0) {
            Picker("Минуты", selection: $setMinutes) {
                ForEach(0..<100, id: \.self) { m in
                    Text("\(m) мин").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Секунды", selection: $setSeconds) {
                ForEach(0..<60, id: \.self) { s in
                    Text("\(s) сек").tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 120)
        .compositingGroup()
        .clipped()
        .opacity(phase == .idle ? 1 : 0)
        .allowsHitTesting(phase == .idle)
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            Button(action: reset) {
                Label("Сброс", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(fill: Color.primary.opacity(0.1), foreground: .primary))
            .disabled(phase == .idle)
            .opacity(phase == .idle ? 0.4 : 1)

            Button(action: primaryAction) {
                Label(primaryTitle, systemImage: primaryIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(fill: .orange, foreground: .white))
            .disabled(primaryDisabled)
            .opacity(primaryDisabled ? 0.4 : 1)
        }
    }

    // MARK: - Derived values

    private var pickedSeconds: Int { setMinutes * 60 + setSeconds }

    private var displaySeconds: Int { Int(ceil(max(remaining, 0))) }

    private var timeString: String {
        String(format: "%02d:%02d", displaySeconds / 60, displaySeconds % 60)
    }

    private var progress: Double {
        switch phase {
        case .idle: return 1
        case .finished: return 0
        default: return total > 0 ? max(0, min(1, remaining / total)) : 0
        }
    }

    private var subtitle: String {
        switch phase {
        case .idle: return "Установите время"
        case .running: return "Идёт отсчёт"
        case .paused: return "Пауза"
        case .finished: return "Время вышло!"
        }
    }

    private var primaryTitle: String {
        switch phase {
        case .idle: return "Старт"
        case .running: return "Пауза"
        case .paused: return "Продолжить"
        case .finished: return "Ещё раз"
        }
    }

    private var primaryIcon: String {
        switch phase {
        case .running: return "pause.fill"
        case .finished: return "arrow.clockwise"
        default: return "play.fill"
        }
    }

    private var primaryDisabled: Bool {
        (phase == .idle || phase == .finished) && pickedSeconds == 0
    }

    // MARK: - Logic

    private func tick() {
        guard phase == .running else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 {
            finish()
        } else {
            remaining = left
        }
    }

    private func finish() {
        remaining = 0
        burst = false
        phase = .finished
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.async {
            burst = true
        }
    }

    private func primaryAction() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch phase {
        case .idle, .finished:
            let t = TimeInterval(pickedSeconds)
            guard t > 0 else { return }
            total = t
            remaining = t
            endDate = Date().addingTimeInterval(t)
            burst = false
            phase = .running
        case .running:
            remaining = max(endDate.timeIntervalSinceNow, 0)
            phase = .paused
        case .paused:
            endDate = Date().addingTimeInterval(remaining)
            phase = .running
        }
    }

    private func reset() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        burst = false
        phase = .idle
        total = TimeInterval(pickedSeconds)
        remaining = total
    }

    private func pickersChanged() {
        guard phase == .idle else { return }
        total = TimeInterval(pickedSeconds)
        remaining = total
    }
}

// MARK: - Button style

private struct PillButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundColor(foreground)
            .padding(.vertical, 18)
            .background(fill, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
