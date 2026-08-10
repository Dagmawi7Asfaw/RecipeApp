import AVFoundation
import AudioToolbox
import SwiftUI

struct CookingModeView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: RecipeModel
    
    @State private var currentStepIndex: Int = 0
    @State private var timerSecondsRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var timer: Timer? = nil
    
    // Voice Assistant
    @State private var isSpeaking: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    var sortedSteps: [StepModel] {
        recipe.viewSortedSteps
    }
    
    var currentStep: StepModel? {
        guard currentStepIndex < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress Bar
                ProgressView(value: Double(currentStepIndex + 1), total: Double(max(1, sortedSteps.count)))
                    .padding(.horizontal)
                
                HStack {
                    Text("Step \(currentStepIndex + 1) of \(sortedSteps.count)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // Read Aloud Button
                    Button {
                        toggleSpeech()
                    } label: {
                        Label(isSpeaking ? "Pause Audio" : "Read Aloud", systemImage: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                
                if let step = currentStep {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(step.instruction)
                                .font(.title2.weight(.medium))
                                .multilineTextAlignment(.leading)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Timer Section
                            if step.timerDurationMinutes > 0 {
                                VStack(spacing: 12) {
                                    Text("Step Timer (\(step.timerDurationMinutes) min)")
                                        .font(.headline)
                                    
                                    Text(formattedTime(timerSecondsRemaining))
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(timerSecondsRemaining == 0 ? .green : .accentColor)
                                    
                                    HStack(spacing: 20) {
                                        Button {
                                            toggleTimer()
                                        } label: {
                                            Label(isTimerRunning ? "Pause" : "Start", systemImage: isTimerRunning ? "pause.fill" : "play.fill")
                                                .font(.headline)
                                                .padding()
                                                .frame(width: 120)
                                                .background(isTimerRunning ? Color.orange : Color.green)
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                        }
                                        
                                        Button {
                                            resetTimer()
                                        } label: {
                                            Label("Reset", systemImage: "arrow.counterclockwise")
                                                .font(.headline)
                                                .padding()
                                                .frame(width: 120)
                                                .background(Color.gray.opacity(0.3))
                                                .foregroundColor(.primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("Bon Appétit!")
                            .font(.largeTitle.bold())
                        Text("You have completed all steps for \(recipe.name).")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    Button {
                        if currentStepIndex > 0 {
                            stopSpeech()
                            currentStepIndex -= 1
                            setupStepTimer()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(currentStepIndex > 0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
                        .foregroundColor(currentStepIndex > 0 ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(currentStepIndex == 0)
                    
                    Button {
                        stopSpeech()
                        if currentStepIndex < sortedSteps.count {
                            currentStepIndex += 1
                            setupStepTimer()
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(currentStepIndex < sortedSteps.count - 1 ? "Next Step" : (currentStepIndex == sortedSteps.count - 1 ? "Finish" : "Close"))
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Hands-Free Cooking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        stopSpeech()
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupStepTimer()
            }
            .onDisappear {
                stopTimer()
                stopSpeech()
            }
        }
    }
    
    private func toggleSpeech() {
        if speechSynthesizer.isSpeaking {
            if speechSynthesizer.isPaused {
                speechSynthesizer.continueSpeaking()
                isSpeaking = true
            } else {
                speechSynthesizer.pauseSpeaking(at: .immediate)
                isSpeaking = false
            }
        } else if let step = currentStep {
            let utterance = AVSpeechUtterance(string: "Step \(currentStepIndex + 1): \(step.instruction)")
            utterance.rate = 0.48
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(utterance)
            isSpeaking = true
        }
    }
    
    private func stopSpeech() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    private func setupStepTimer() {
        stopTimer()
        if let step = currentStep, step.timerDurationMinutes > 0 {
            timerSecondsRemaining = step.timerDurationMinutes * 60
        } else {
            timerSecondsRemaining = 0
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            isTimerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timerSecondsRemaining > 0 {
                    timerSecondsRemaining -= 1
                } else {
                    stopTimer()
                    AudioServicesPlaySystemSound(1005) // Alarm sound
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        setupStepTimer()
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
