//
//  AITriviaGameView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI

struct AITriviaGameView: View {
    let questions: [TriviaQuestion]
    let category: String
    let difficulty: String
    
    @StateObject private var aiManager = AIModelManager.shared
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [UserAnswer]
    @State private var aiAnswers: [UserAnswer]
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var showResults = false
    @State private var isAIThinking = false
    @State private var aiResponseTime: TimeInterval = 0
    
    private let totalTime: Int
    private let timePerQuestion = 20 // 20 seconds per question for AI games
    
    init(questions: [TriviaQuestion], category: String, difficulty: String) {
        self.questions = questions
        self.category = category
        self.difficulty = difficulty
        _userAnswers = State(initialValue: questions.map { UserAnswer(question: $0, selectedAnswer: nil) })
        _aiAnswers = State(initialValue: questions.map { UserAnswer(question: $0, selectedAnswer: nil) })
        
        // Total time for AI games
        let calculatedTime = questions.count * timePerQuestion
        self.totalTime = calculatedTime
        _timeRemaining = State(initialValue: calculatedTime)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.indigo.opacity(0.2), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Timer and Score Header
                VStack(spacing: 12) {
                    // Timer
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(timeString)
                            .font(.title2)
                            .bold()
                            .foregroundColor(timeRemaining < 10 ? .red : .primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Score comparison
                    HStack(spacing: 20) {
                        // User Score
                        VStack(spacing: 4) {
                            Text("You")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(userScore)")
                                .font(.title)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("VS")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // AI Score
                        VStack(spacing: 4) {
                            Text("AI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(aiScore)")
                                .font(.title)
                                .bold()
                                .foregroundColor(.indigo)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Progress
                    HStack {
                        Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                        .tint(.indigo)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Question Content - Force recreation on index change
                AIQuestionContentView(
                    currentIndex: currentQuestionIndex,
                    questions: questions,
                    userAnswers: $userAnswers,
                    aiAnswers: $aiAnswers,
                    isAIThinking: $isAIThinking,
                    aiResponseTime: $aiResponseTime
                )
                .id(currentQuestionIndex) // Force complete recreation when index changes
                
                // Next/Submit button
                if userAnswers[currentQuestionIndex].selectedAnswer != nil &&
                   aiAnswers[currentQuestionIndex].selectedAnswer != nil {
                    Button(action: nextQuestion) {
                        HStack {
                            if currentQuestionIndex < questions.count - 1 {
                                Text("Next Question")
                                Image(systemName: "arrow.right")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Finish Game")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.indigo, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("AI Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: startGame)
        .onDisappear(perform: cleanup)
        .navigationDestination(isPresented: $showResults) {
            AIResultsView(
                questions: questions,
                userAnswers: userAnswers,
                aiAnswers: aiAnswers,
                category: category,
                difficulty: difficulty
            )
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var userScore: Int {
        userAnswers.filter { $0.isCorrect == true }.count
    }
    
    private var aiScore: Int {
        aiAnswers.filter { $0.isCorrect == true }.count
    }
    
    private func startGame() {
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time's up - finish game
                finishGame()
            }
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
    }
    
    private func finishGame() {
        cleanup()
        showResults = true
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            // AI will be triggered by the AIQuestionContentView onAppear
        } else {
            finishGame()
        }
    }
}

// MARK: - AI Question Content View

struct AIQuestionContentView: View {
    let currentIndex: Int
    let questions: [TriviaQuestion]
    @Binding var userAnswers: [UserAnswer]
    @Binding var aiAnswers: [UserAnswer]
    @Binding var isAIThinking: Bool
    @Binding var aiResponseTime: TimeInterval
    
    // Local state for this question
    @State private var userSelectedIndex: Int? = nil
    @State private var aiSelectedIndex: Int? = nil
    @State private var spinnerRotation: Double = 0
    @State private var dotsAnimating: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if currentIndex < questions.count {
                    let question = questions[currentIndex]
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Badges
                        HStack {
                            Label(question.category, systemImage: "folder.fill")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.indigo.opacity(0.2))
                                .foregroundColor(.indigo)
                                .cornerRadius(8)
                            
                            Label(question.difficulty.capitalized, systemImage: "chart.bar.fill")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(difficultyColor.opacity(0.2))
                                .foregroundColor(difficultyColor)
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                        
                        // Question
                        Text(question.decodedQuestion)
                            .font(.title3)
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Divider()
                        
                        // Answer buttons
                        VStack(spacing: 12) {
                            ForEach(Array(question.allAnswers.enumerated()), id: \.offset) { index, answer in
                                AIAnswerButton(
                                    text: question.decodedAllAnswers[index],
                                    index: index,
                                    userSelectedIndex: $userSelectedIndex,
                                    aiSelectedIndex: $aiSelectedIndex,
                                    isDisabled: userSelectedIndex != nil,
                                    onTap: {
                                        if userSelectedIndex == nil {
                                            userSelectedIndex = index
                                            userAnswers[currentIndex].selectedAnswer = answer
                                        }
                                    }
                                )
                            }
                        }
                        
                        // AI Status - Always visible when AI is active
                        let _ = print("🎨 UI Update: isAIThinking=\(isAIThinking), aiSelectedIndex=\(String(describing: aiSelectedIndex))")
                        if isAIThinking || aiSelectedIndex != nil {
                            HStack {
                                if isAIThinking {
                                    HStack(spacing: 12) {
                                        // Brain icon with clean spinner
                                        ZStack {
                                            // Pulsing glow behind everything
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.indigo.opacity(0.2), Color.cyan.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 36, height: 36)
                                                .scaleEffect(isAIThinking ? 1.2 : 1.0)
                                                .opacity(isAIThinking ? 0.0 : 0.5)
                                                .animation(
                                                    .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                                    value: isAIThinking
                                                )
                                            
                                            // Background circle track
                                            Circle()
                                                .stroke(Color.indigo.opacity(0.15), lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                            
                                            // Animated spinner
                                            Circle()
                                                .trim(from: 0, to: 0.75)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.indigo, Color.cyan],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                                )
                                                .frame(width: 32, height: 32)
                                                .rotationEffect(.degrees(spinnerRotation))
                                                .onAppear {
                                                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                                        spinnerRotation = 360
                                                    }
                                                }
                                            
                                            // Brain icon in center
                                            Image(systemName: "brain")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.indigo)
                                                .scaleEffect(isAIThinking ? 1.0 : 0.9)
                                                .animation(
                                                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                                    value: isAIThinking
                                                )
                                        }
                                        
                                        Text("AI is thinking")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.indigo)
                                        
                                        // Subtle dots animation
                                        HStack(spacing: 2) {
                                            ForEach(0..<3) { index in
                                                Circle()
                                                    .fill(Color.indigo.opacity(0.8))
                                                    .frame(width: 3, height: 3)
                                                    .scaleEffect(dotsAnimating ? 1.0 : 0.5)
                                                    .animation(
                                                        .easeInOut(duration: 0.6)
                                                            .repeatForever()
                                                            .delay(Double(index) * 0.15),
                                                        value: dotsAnimating
                                                    )
                                                    .onAppear {
                                                        dotsAnimating = true
                                                    }
                                            }
                                        }
                                    }
                                } else if aiSelectedIndex != nil {
                                    HStack(spacing: 8) {
                                        // Success checkmark with subtle animation
                                        ZStack {
                                            Circle()
                                                .fill(Color.green.opacity(0.15))
                                                .frame(width: 24, height: 24)
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.green)
                                                .scaleEffect(1.0)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                        
                                        Text("AI answered in \(String(format: "%.1fs", aiResponseTime))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            // Sync state on appear
            if currentIndex < userAnswers.count {
                if let answer = userAnswers[currentIndex].selectedAnswer {
                    userSelectedIndex = questions[currentIndex].allAnswers.firstIndex(of: answer)
                }
            }
            if currentIndex < aiAnswers.count {
                if let answer = aiAnswers[currentIndex].selectedAnswer {
                    aiSelectedIndex = questions[currentIndex].allAnswers.firstIndex(of: answer)
                }
            }
            
            // Trigger AI if needed
            if currentIndex < questions.count && aiAnswers[currentIndex].selectedAnswer == nil {
                triggerAI()
            }
        }
        .onChange(of: aiAnswers[currentIndex].selectedAnswer) { _, newValue in
            if let answer = newValue {
                aiSelectedIndex = questions[currentIndex].allAnswers.firstIndex(of: answer)
            }
        }
        .onChange(of: isAIThinking) { _, newValue in
            if newValue {
                // Reset animation states when AI starts thinking
                spinnerRotation = 0
                dotsAnimating = false
                
                // Start animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        spinnerRotation = 360
                    }
                    dotsAnimating = true
                }
            }
        }
    }
    
    private var difficultyColor: Color {
        guard currentIndex < questions.count else { return .gray }
        switch questions[currentIndex].difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }
    
    private func triggerAI() {
        guard currentIndex < questions.count else { return }
        let question = questions[currentIndex]
        
        print("🤖 Starting AI thinking for question \(currentIndex + 1)")
        isAIThinking = true
        let startTime = Date()
        
        Task {
            do {
                let aiManager = AIModelManager.shared
                let result = try await aiManager.ensureAndGenerateAnswer(
                    question: question.question,
                    category: question.category,
                    difficulty: question.difficulty,
                    correctAnswer: question.correctAnswer,
                    incorrectAnswers: question.incorrectAnswers
                )
                
                let responseTime = Date().timeIntervalSince(startTime)
                let minDelay: Double = question.difficulty.lowercased() == "hard" ? 2.0 : 1.5
                let additionalDelay = max(0, minDelay - responseTime)
                
                if additionalDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(additionalDelay * 1_000_000_000))
                }
                
                await MainActor.run {
                    print("🤖 AI answered: \(result.answer) in \(String(format: "%.1f", responseTime + additionalDelay))s")
                    self.aiAnswers[currentIndex].selectedAnswer = result.answer
                    self.aiResponseTime = responseTime + additionalDelay
                    self.isAIThinking = false
                }
            } catch {
                await MainActor.run {
                    self.aiAnswers[currentIndex].selectedAnswer = question.allAnswers.randomElement() ?? ""
                    self.aiResponseTime = 2.0
                    self.isAIThinking = false
                }
            }
        }
    }
}

// MARK: - AI Answer Button

struct AIAnswerButton: View {
    let text: String
    let index: Int
    @Binding var userSelectedIndex: Int?
    @Binding var aiSelectedIndex: Int?
    let isDisabled: Bool
    let onTap: () -> Void
    
    private var isUserSelected: Bool {
        userSelectedIndex == index
    }
    
    private var isAISelected: Bool {
        aiSelectedIndex == index
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isUserSelected || isAISelected ? .white : .primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isUserSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                    if isAISelected {
                        Image(systemName: "cpu")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isUserSelected && !isAISelected ? 0.6 : 1.0)
    }
    
    private var backgroundGradient: LinearGradient {
        if isUserSelected && isAISelected {
            return LinearGradient(
                colors: [Color.purple, Color.indigo],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if isUserSelected {
            return LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if isAISelected {
            return LinearGradient(
                colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var borderColor: Color {
        if isUserSelected {
            return Color.purple
        } else if isAISelected {
            return Color.indigo
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: CGFloat {
        (isUserSelected || isAISelected) ? 2 : 1
    }
}

#Preview {
    AITriviaGameView(
        questions: [],
        category: "General",
        difficulty: "Medium"
    )
}
