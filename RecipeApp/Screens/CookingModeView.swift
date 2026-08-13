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
    @State private var completedSteps: Set<Int> = []
    @State private var dragOffset: CGFloat = 0

    // Voice Assistant
    @State private var isSpeaking: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var sortedSteps: [StepModel] { recipe.viewSortedSteps }
    var currentStep: StepModel? {
        guard currentStepIndex < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex]
    }
    var isFinished: Bool { currentStepIndex >= sortedSteps.count }
    var progress: Double { Double(currentStepIndex) / Double(max(1, sortedSteps.count)) }

    var body: some View {
        ZStack {
            // Background
            backgroundView

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Progress
                progressSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                // Main content
                if isFinished {
                    completionView
                        .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity),
                                                removal: .opacity))
                } else if let step = currentStep {
                    stepContent(step)
                        .id(currentStepIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer(minLength: 0)

                // Navigation
                if !isFinished {
                    navigationBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
        }
        .onAppear { setupStepTimer() }
        .onDisappear { stopTimer(); stopSpeech() }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 60
                    if value.translation.width < -threshold {
                        navigateNext()
                    } else if value.translation.width > threshold && currentStepIndex > 0 {
                        navigatePrevious()
                    }
                }
        )
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            if let image = recipe.viewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 32)
                    .scaleEffect(1.1)
                    .overlay(Color.black.opacity(0.65))
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.9), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                stopSpeech()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Exit")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            VStack(spacing: 1) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Hands-Free Cooking")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                toggleSpeech()
            } label: {
                Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSpeaking ? .yellow : .white.opacity(0.85))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle().strokeBorder(isSpeaking ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 8) {
            // Step bubbles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<sortedSteps.count, id: \.self) { idx in
                        Circle()
                            .fill(stepBubbleColor(idx))
                            .frame(width: idx == currentStepIndex ? 10 : 7,
                                   height: idx == currentStepIndex ? 10 : 7)
                            .animation(.spring(response: 0.3), value: currentStepIndex)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 14)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .accentColor], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * progress), height: 4)
                        .animation(.spring(response: 0.5), value: currentStepIndex)
                }
            }
            .frame(height: 4)

            HStack {
                Text("Step \(min(currentStepIndex + 1, sortedSteps.count)) of \(sortedSteps.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private func stepBubbleColor(_ idx: Int) -> Color {
        if completedSteps.contains(idx) { return .green }
        if idx == currentStepIndex { return .white }
        return .white.opacity(0.3)
    }

    // MARK: - Step Content

    private func stepContent(_ step: StepModel) -> some View {
        VStack(spacing: 20) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.accentColor, Color(hue: 0.62, saturation: 0.7, brightness: 0.9)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .shadow(color: .accentColor.opacity(0.4), radius: 10, y: 4)
                Text("\(step.stepNumber)")
                    .font(.title2.weight(.black))
                    .foregroundColor(.white)
            }

            // Instruction card
            ScrollView {
                Text(step.instruction)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .lineSpacing(4)
            }
            .frame(maxHeight: 260)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            )
            .padding(.horizontal, 20)

            // Timer if needed
            if step.timerDurationMinutes > 0 {
                timerCard(step)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Timer Card

    private func timerCard(_ step: StepModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                Text("Step Timer — \(step.timerDurationMinutes) min")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }

            Text(formattedTime(timerSecondsRemaining))
                .font(.system(size: 52, weight: .black, design: .monospaced))
                .foregroundColor(timerSecondsRemaining == 0 ? .green : .white)
                .shadow(color: timerSecondsRemaining == 0 ? .green.opacity(0.6) : .clear, radius: 12)
                .contentTransition(.numericText())

            HStack(spacing: 16) {
                Button { toggleTimer() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        Text(isTimerRunning ? "Pause" : "Start")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(isTimerRunning ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: (isTimerRunning ? Color.orange : Color.green).opacity(0.4), radius: 8, y: 3)
                }

                Button { resetTimer() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body.weight(.semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green.opacity(0.3), .green.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
            }
            .shadow(color: .green.opacity(0.4), radius: 20)

            VStack(spacing: 8) {
                Text("Bon Appétit!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("You've completed all \(sortedSteps.count) steps for")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text(recipe.name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
            }

            Button {
                stopSpeech()
                dismiss()
            } label: {
                Text("Close Cooking Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 14) {
            Button {
                navigatePrevious()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(currentStepIndex > 0 ? .white : .white.opacity(0.3))
                .frame(width: 100)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(currentStepIndex == 0)

            Button {
                navigateNext()
            } label: {
                HStack(spacing: 8) {
                    if currentStepIndex < sortedSteps.count - 1 {
                        Text("Next Step")
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: currentStepIndex < sortedSteps.count - 1
                            ? [.accentColor, Color(hue: 0.62, saturation: 0.7, brightness: 0.9)]
                            : [.green, .mint],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 4)
            }
        }
    }

    // MARK: - Navigation Actions

    private func navigateNext() {
        stopSpeech()
        completedSteps.insert(currentStepIndex)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            currentStepIndex += 1
        }
        setupStepTimer()
    }

    private func navigatePrevious() {
        guard currentStepIndex > 0 else { return }
        stopSpeech()
        completedSteps.remove(currentStepIndex - 1)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            currentStepIndex -= 1
        }
        setupStepTimer()
    }

    // MARK: - Speech

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

    // MARK: - Timer

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
                    AudioServicesPlaySystemSound(1005)
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
