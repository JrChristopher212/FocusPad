import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

// MARK: - TimerModel

class TimerModel: ObservableObject {
    enum AlertSound: String, CaseIterable, Identifiable {
        case beep          = "Beep 1005"
        case system1031    = "Chime 1031"
        case system1014    = "Blerr 1014"
        case system1020    = "Climb 1020"
        case system1024    = "Train 1024"
        case system1027    = "DumDum 1027"
        case system1028    = "Tink 1028"
        case system1030    = "Trumpet 1030"
        case system1032    = "Ominous 1032"
        case system1035    = "DumDum 1035"
        case system1036    = "TutTut 1036"
        
        var id: String { rawValue }
        
        /// Return the SystemSoundID associated with each sound.
        var soundID: SystemSoundID {
            switch self {
            case .beep:        return 1005
            case .system1031:  return 1031
            case .system1014:  return 1014
            case .system1020:  return 1020
            case .system1024:  return 1024
            case .system1027:  return 1027
            case .system1028:  return 1028
            case .system1030:  return 1030
            case .system1032:  return 1032
            case .system1035:  return 1035
            case .system1036:  return 1036
            }
        }
    }
    
    @Published var isRunning = false
    @Published var timeRemaining: Int
    @Published var alertSound: AlertSound = .beep
    
   //System sound IDs to play at 1 minute, 30 seconds, and 15 seconds
    var oneMinuteSoundID: SystemSoundID = 1013
    var thirtySecondSoundID: SystemSoundID = 1009
    var fifteenSecondSoundID: SystemSoundID = 1005
    
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

            // Check for reminder thresholds
            switch timeRemaining {
            case 60:
                AudioServicesPlaySystemSound(oneMinuteSoundID)      // 1 minute left
            case 30:
                AudioServicesPlaySystemSound(thirtySecondSoundID)   // 30 seconds left
            case 15:
                AudioServicesPlaySystemSound(fifteenSecondSoundID)  // 15 seconds left
            default:
                break
            }
        } else {
            pause()
            playAlert()  // Final alert at 0
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
                // Replace the old Menu block with this:
                HStack {
                    // Start/Pause button with drop‑down sound options
                    Menu {
                        ForEach(TimerModel.AlertSound.allCases) { option in
                            Button(option.rawValue) {
                                timerModel.alertSound = option
                            }
                        }
                    } label: {
                        Text(timerModel.isRunning ? "Pause Timer" : "Start Timer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } primaryAction: {
                        if timerModel.isRunning {
                            timerModel.pause()
                        } else {
                            timerModel.start()
                        }
                    }

                    // Reset button
                    Button(action: {
                        timerModel.reset()
                    }) {
                        Text("Reset")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

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

