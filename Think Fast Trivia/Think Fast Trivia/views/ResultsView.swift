//
//  ResultsView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import SwiftUI
import ParseSwift

struct ResultsView: View {
    let questions: [TriviaQuestion]
    let userAnswers: [UserAnswer]
    let timeTaken: Int // Time taken in seconds
    let category: String
    let difficulty: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var showNewGameConfirmation = false
    @State private var scoreSaved = false
    @State private var isSavingScore = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var showHighScores = false
    
    private var score: Int {
        userAnswers.filter { $0.isCorrect == true }.count
    }
    
    private var percentage: Double {
        Double(score) / Double(questions.count) * 100
    }
    
    private var scoreEmoji: String {
        switch percentage {
        case 90...100: return "🏆"
        case 75..<90: return "🎉"
        case 60..<75: return "👍"
        case 40..<60: return "😐"
        default: return "📚"
        }
    }
    
    private var scoreMessage: String {
        switch percentage {
        case 90...100: return "Outstanding!"
        case 75..<90: return "Great Job!"
        case 60..<75: return "Good Effort!"
        case 40..<60: return "Keep Practicing!"
        default: return "Study More!"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score Card
                VStack(spacing: 16) {
                    Text(scoreEmoji)
                        .font(.system(size: 80))
                    
                    Text(scoreMessage)
                        .font(.title)
                        .bold()
                    
                    Text("\(score) / \(questions.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text(String(format: "%.0f%% Correct", percentage))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // TEMPORARILY HIDDEN - Save Score Button
                    /*
                    // Save Score Button (only show if logged in and not saved)
                    if User.current != nil && !scoreSaved {
                        Button(action: saveScore) {
                            HStack {
                                if isSavingScore {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text(isSavingScore ? "Saving..." : "Save Score")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
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
                        .disabled(isSavingScore)
                    } else if scoreSaved {
                    */
                    
                    // Show saved message even though we're not actually saving
                    if false {
                        Label("Score Saved!", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding()
                
                // Answer Review
                VStack(alignment: .leading, spacing: 16) {
                    Text("Answer Review")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ForEach(Array(userAnswers.enumerated()), id: \.element.id) { index, answer in
                        ResultCard(
                            questionNumber: index + 1,
                            question: answer.question,
                            userAnswer: answer.selectedAnswer,
                            isCorrect: answer.isCorrect
                        )
                    }
                }
                .padding(.bottom)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showNewGameConfirmation = true }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Menu")
                    }
                }
            }
            
            // TEMPORARILY HIDDEN - High Scores button
            /*
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showHighScores = true }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("High Scores")
                    }
                    .foregroundColor(.yellow)
                }
            }
            */
        }
        .sheet(isPresented: $showHighScores) {
            HighScoresView()
        }
        .alert("Return to Menu?", isPresented: $showNewGameConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Return", role: .destructive) {
                // Dismiss all the way back to the root
                resetToMainMenu()
            }
        } message: {
            Text("Are you sure you want to return to the main menu?")
        }
        .alert("Error Saving Score", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    private func saveScore() {
        // Only save if user is logged in
        guard User.current != nil else {
            saveErrorMessage = "You must be logged in to save scores"
            showSaveError = true
            return
        }
        
        // Prevent duplicate saves
        guard !scoreSaved else {
            print("⚠️ Score already saved, preventing duplicate save")
            return
        }
        
        isSavingScore = true
        saveErrorMessage = ""
        
        print("💾 Starting score save: \(score)/\(questions.count) in \(category) - \(difficulty)")
        
        Task {
            do {
                try await ParseService.shared.saveGameScore(
                    score: score,
                    totalQuestions: questions.count,
                    category: category,
                    difficulty: difficulty,
                    timeTaken: timeTaken
                )
                
                await MainActor.run {
                    print("✅ Score saved successfully!")
                    isSavingScore = false
                    scoreSaved = true
                    
                    // Show success feedback
                    withAnimation(.easeInOut) {
                        // Trigger UI update to show success state
                    }
                }
            } catch {
                print("❌ Error saving score: \(error)")
                await MainActor.run {
                    isSavingScore = false
                    saveErrorMessage = "Failed to save score: \(error.localizedDescription)"
                    showSaveError = true
                    scoreSaved = false // Allow retry
                }
            }
        }
    }
    
    private func resetToMainMenu() {
        // This will dismiss the entire navigation stack back to the root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Reset the navigation stack to root
            window.rootViewController?.dismiss(animated: false, completion: nil)
            
            // If using NavigationStack, pop to root
            if let navController = window.rootViewController as? UINavigationController {
                navController.popToRootViewController(animated: false)
            } else if let rootVC = window.rootViewController {
                // Find and reset any NavigationStack in the view hierarchy
                rootVC.children.forEach { child in
                    if let nav = child as? UINavigationController {
                        nav.popToRootViewController(animated: false)
                    }
                }
            }
        }
        
        // Also dismiss this view
        dismiss()
    }
}

struct ResultCard: View {
    let questionNumber: Int
    let question: TriviaQuestion
    let userAnswer: String?
    let isCorrect: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline)
                
                Spacer()
                
                if let isCorrect = isCorrect {
                    Label(
                        isCorrect ? "Correct" : "Incorrect",
                        systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.subheadline)
                    .bold()
                } else {
                    Label("Unanswered", systemImage: "questionmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                }
            }
            
            // Question
            Text(question.decodedQuestion)
                .font(.body)
            
            Divider()
            
            // User's answer
            if let userAnswer = userAnswer {
                HStack(alignment: .top) {
                    Text("Your answer:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(userAnswer.htmlDecoded)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(isCorrect == true ? .green : .red)
                }
            } else {
                Text("No answer selected")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .italic()
            }
            
            // Correct answer (if wrong or unanswered)
            if isCorrect != true {
                HStack(alignment: .top) {
                    Text("Correct answer:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(question.decodedCorrectAnswer)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}
