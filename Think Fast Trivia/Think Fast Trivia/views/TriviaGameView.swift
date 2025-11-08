//
//  TriviaGameView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import SwiftUI

struct TriviaGameView: View {
    let questions: [TriviaQuestion]
    
    @State private var userAnswers: [UserAnswer]
    @State private var currentQuestionIndex = 0
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var showResults = false
    @State private var showSubmitConfirmation = false
    @State private var showTimeUpAlert = false
    
    private let totalTime: Int
    
    init(questions: [TriviaQuestion]) {
        self.questions = questions
        _userAnswers = State(initialValue: questions.map { UserAnswer(question: $0, selectedAnswer: nil) })
        
        // 30 seconds per question
        let calculatedTime = questions.count * 30
        self.totalTime = calculatedTime
        _timeRemaining = State(initialValue: calculatedTime)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Timer and Progress Header
                VStack(spacing: 12) {
                    // Timer
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(timeString)
                            .font(.title2)
                            .bold()
                            .foregroundColor(timeRemaining < 30 ? .red : .primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Progress
                    HStack {
                        Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                            .font(.headline)
                        Spacer()
                        Text("\(answeredCount)/\(questions.count) answered")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                        .tint(.purple)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Question Content - Key change: Move entire content into a separate view
                QuestionContentView(
                    currentIndex: currentQuestionIndex,
                    questions: questions,
                    userAnswers: $userAnswers
                )
                .id(currentQuestionIndex) // Force complete recreation when index changes
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    // Previous Button
                    Button(action: previousQuestion) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentQuestionIndex > 0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        .foregroundColor(currentQuestionIndex > 0 ? .primary : .gray)
                        .cornerRadius(10)
                    }
                    .disabled(currentQuestionIndex == 0)
                    
                    // Next or Submit Button
                    if currentQuestionIndex < questions.count - 1 {
                        Button(action: nextQuestion) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    } else {
                        Button(action: { showSubmitConfirmation = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Think Fast!")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .navigationDestination(isPresented: $showResults) {
            ResultsView(questions: questions, userAnswers: userAnswers)
        }
        .alert("Submit Answers?", isPresented: $showSubmitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Submit", role: .destructive) {
                submitAnswers()
            }
        } message: {
            Text("Are you sure you want to submit? You have answered \(answeredCount) out of \(questions.count) questions.")
        }
        .alert("Time's Up!", isPresented: $showTimeUpAlert) {
            Button("View Results") {
                submitAnswers()
            }
        } message: {
            Text("Your time has expired. Your answers have been automatically submitted.")
        }
        .onChange(of: timeRemaining) { oldValue, newValue in
            if newValue == 0 && !showResults {
                showTimeUpAlert = true
            }
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var answeredCount: Int {
        userAnswers.filter { $0.selectedAnswer != nil }.count
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextQuestion() {
        print("🔵 Next button tapped. Current index: \(currentQuestionIndex)")
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            print("🟢 Index updated to: \(currentQuestionIndex)")
            print("📝 Current question: \(questions[currentQuestionIndex].decodedQuestion)")
        } else {
            print("🔴 Already at last question")
        }
    }
    
    private func previousQuestion() {
        print("⬅️ Previous button tapped. Current index: \(currentQuestionIndex)")
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            print("🟢 Index updated to: \(currentQuestionIndex)")
            print("📝 Current question: \(questions[currentQuestionIndex].decodedQuestion)")
        }
    }
    
    private func submitAnswers() {
        stopTimer()
        showResults = true
    }
}

// Separate view for the question content - this ensures complete recreation
struct QuestionContentView: View {
    let currentIndex: Int
    let questions: [TriviaQuestion]
    @Binding var userAnswers: [UserAnswer]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if currentIndex < questions.count {
                    let _ = print("🟡 Rendering question at index: \(currentIndex)")
                    let _ = print("🟡 Question ID: \(questions[currentIndex].id)")
                    let _ = print("🟡 Question text: \(questions[currentIndex].decodedQuestion.prefix(50))...")
                    
                    QuestionCardView(
                        question: questions[currentIndex],
                        selectedAnswer: $userAnswers[currentIndex].selectedAnswer
                    )
                    .padding()
                }
            }
        }
        .scrollDisabled(false)
        .scrollBounceBehavior(.basedOnSize)
    }
}
