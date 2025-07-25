import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

// MARK: - TimerModel

class TimerModel: ObservableObject {
    enum AlertSound: String, CaseIterable, Identifiable {
        case beep = "Beep"
        case system1 = "System Sound 1000"
        case system2 = "System Sound 1013"

        var id: String { rawValue }
    }

    @Published var isRunning = false
    @Published var timeRemaining: Int
    @Published var isWorkSession = true
    @Published var alertSound: AlertSound = .beep

    var workDuration = 25 * 60
    var breakDuration = 5 * 60

    private var timer: AnyCancellable?

    init() {
        // start with a work session
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
            // When timer reaches zero, switch sessions and play alert
            isWorkSession.toggle()
            timeRemaining = isWorkSession ? workDuration : breakDuration
            playAlert()
        }
    }

    private func playAlert() {
        switch alertSound {
            case .beep:
                // system beep (new mail tone)
                AudioServicesPlaySystemSound(1005)
        case .system1:
            AudioServicesPlaySystemSound(1000)
              //took out line
             
        case .system2:
            AudioServicesPlaySystemSound(1013)
                //took out line
           
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var timerModel = TimerModel()

    var body: some View {
        ZStack {
            // Background image (add "WorkLifeBackground" image set in Assets)
            Image("WorkLifeBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(timerModel.isWorkSession ? "Work Session" : "Break Session")
                    .font(.title)
                    .padding()

                // Display minutes:seconds (e.g., 24:59)
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

                // Duration customisation controls
                VStack(alignment: .leading) {
                    Text("Customize Durations (minutes)")
                        .font(.headline)
                    HStack {
                        Text("Work")
                            .frame(width: 50, alignment: .leading)
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
                            in: 1...60,
                            step: 1
                            
                        )
                        .accentColor(.blue)
                        Text("\(timerModel.workDuration / 60)m")
                            .frame(width: 40, alignment: .trailing)
                    }
                    HStack {
                        Text("Break")
                            .frame(width: 50, alignment: .leading)
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

                // Alert sound picker
                VStack(alignment: .leading) {
                    Text("Alert Sound")
                        .font(.headline)
                    Picker("Alert Sound", selection: $timerModel.alertSound) {
                        ForEach(TimerModel.AlertSound.allCases) { option in
                            Text(option.rawValue).tag(option)
                }
                        
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                }
                .padding()
            }
        }
    }
}

// MARK: - App entry point

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


