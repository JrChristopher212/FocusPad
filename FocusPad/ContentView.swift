import SwiftUI
import Combine

// MARK: - TimerModel

class TimerModel: ObservableObject {
    @Published var isRunning = false
    @Published var timeRemaining: Int
    @Published var isWorkSession = true

    var workDuration = 25 * 60
    var breakDuration = 5 * 60

    private var timer: AnyCancellable?

    init() {
        self.timeRemaining = workDuration
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        pause()
        timeRemaining = isWorkSession ? workDuration : breakDuration
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            isWorkSession.toggle()
            timeRemaining = isWorkSession ? workDuration : breakDuration
        }
    }
}

// MARK: - ContentView (this is the view you will see)

struct ContentView: View {
    @StateObject private var timerModel = TimerModel()
    @AppStorage("isPaidUser") private var isPaidUser: Bool = false

    // This property builds your UI.
    var body: some View {
        VStack(spacing: 30) {
            Text(timerModel.isWorkSession ? "Work Session" : "Break Session")
                .font(.title)
                .padding()

            // show minutes:seconds
            Text("\(timerModel.timeRemaining / 60) : \(String(format: "%02d", timerModel.timeRemaining % 60))")
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .padding()

            // Start/Pause and Reset buttons
            HStack {
                Button(action: {
                    timerModel.isRunning ? timerModel.pause() : timerModel.start()
                }) {
                    Text(timerModel.isRunning ? "Pause" : "Start")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    timerModel.reset()
                }) {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            // Free vs paid controls
            if isPaidUser {
                VStack(alignment: .leading) {
                    Text("Customize Durations (minutes)")
                        .font(.headline)
                    HStack {
                        Text("Work").frame(width: 50, alignment: .leading)
                        Slider(
                            value: Binding(
                                get: { Double(timerModel.workDuration) / 60 },
                                set: { newValue in
                                    timerModel.workDuration = Int(newValue) * 60
                                    if timerModel.isWorkSession {
                                        timerModel.timeRemaining = timerModel.workDuration
                                    }
                                }
                            ),
                            in: 5...60,
                            step: 1
                        )
                        .accentColor(.blue)
                        Text("\(timerModel.workDuration / 60)m")
                            .frame(width: 40, alignment: .trailing)
                    }
                    HStack {
                        Text("Break").frame(width: 50, alignment: .leading)
                        Slider(
                            value: Binding(
                                get: { Double(timerModel.breakDuration) / 60 },
                                set: { newValue in
                                    timerModel.breakDuration = Int(newValue) * 60
                                    if !timerModel.isWorkSession {
                                        timerModel.timeRemaining = timerModel.breakDuration
                                    }
                                }
                            ),
                            in: 1...30,
                            step: 1
                        )
                        .accentColor(.green)
                        Text("\(timerModel.breakDuration / 60)m")
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                .padding()
            } else {
                Text("Upgrade to Premium to customize work/break durations.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    // TODO: implement real in‑app purchase
                    isPaidUser = true
                }) {
                    Text("Upgrade")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - App entry point


// MARK: - Preview for the canvas (so you can see the phone preview)

#Preview {
    ContentView()
}

