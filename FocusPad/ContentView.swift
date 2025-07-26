import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

// MARK: - TimerModel

class TimerModel: ObservableObject {
    enum AlertSound: String, CaseIterable, Identifiable {
        case beep          = "Beep 1005"
        case system1000    = "Sound 1000"
        case system1001    = "Sound 1001"
        case system1002    = "Sound 1002"
        case system1003    = "Sound 1003"
        case system1004    = "Sound 1004"
        case system1005    = "Sound 1005"
        case system1006    = "Sound 1006"
        case system1007    = "Sound 1007"
        case system1013    = "Sound 1013"
        
        var id: String { rawValue }
        
        /// Return the SystemSoundID associated with each sound.
        var soundID: SystemSoundID {
            switch self {
            case .beep:        return 1005
            case .system1000:  return 1000
            case .system1001:  return 1001
            case .system1002:  return 1002
            case .system1003:  return 1003
            case .system1004:  return 1004
            case .system1005:  return 1005
            case .system1006:  return 1006
            case .system1007:  return 1007
            case .system1013:  return 1013
            }
        }
    }
    
    @Published var isRunning = false
    @Published var timeRemaining: Int
    @Published var alertSound: AlertSound = .beep
    
    /// Duration of the timer in seconds (default 25 minutes)
    var workDuration: Int = 25 * 60 {
        didSet {
            // If the timer isn't running, update timeRemaining to match the new duration
            if !isRunning {
                timeRemaining = workDuration
            }
        }
    }
    
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
        timeRemaining = workDuration
    }
    
    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // When the timer finishes, stop it and play the alert
            pause()
            playAlert()
        }
    }
    
    private func playAlert() {
        AudioServicesPlaySystemSound(alertSound.soundID)
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
                Text("Timer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Display minutes:seconds (e.g., 24:59)
                Text("\(timerModel.timeRemaining / 60) : \(String(format: "%02d", timerModel.timeRemaining % 60))")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .padding()
                
                // Work duration slider
                VStack(alignment: .leading) {
                    Text("Timer Duration (minutes)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack {
                        Text("Work")
                            .frame(width: 50, alignment: .leading)
                        Slider(
                            value: Binding(
                                get: { Double(timerModel.workDuration) / 60.0 },
                                set: { newValue in
                                    timerModel.workDuration = Int(newValue * 60)
                                }
                            ),
                            in: 1...60,
                            step: 1
                        )
                        .accentColor(.blue)
                        Text("\(timerModel.workDuration / 60)m")
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                .padding()
                
                // Single button with drop-down list of alert sounds
                Menu {
                    // Provide all 10 sound options
                    ForEach(TimerModel.AlertSound.allCases) { option in
                        Button(option.rawValue) {
                            timerModel.alertSound = option
                        }
                    }
                } label: {
                    // Visible button that starts or pauses the timer
                    Text(timerModel.isRunning ? "Pause Timer" : "Start Timer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } primaryAction: {
                    // Primary action: toggle start/pause when tapped
                    if timerModel.isRunning {
                        timerModel.pause()
                    } else {
                        timerModel.start()
                    }
                }
                .padding(.horizontal)
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

