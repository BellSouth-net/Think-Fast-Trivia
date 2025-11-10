//
//  AIResultsView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct AIResultsView: View {
    let questions: [TriviaQuestion]
    let userAnswers: [UserAnswer]
    let aiAnswers: [UserAnswer]
    let category: String
    let difficulty: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var showNewGameConfirmation = false
    @State private var scoreSaved = false
    @State private var isSavingScore = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    
    private var userScore: Int {
        userAnswers.filter { $0.isCorrect == true }.count
    }
    
    private var aiScore: Int {
        aiAnswers.filter { $0.isCorrect == true }.count
    }
    
    private var userPercentage: Double {
        Double(userScore) / Double(questions.count) * 100
    }
    
    private var aiPercentage: Double {
        Double(aiScore) / Double(questions.count) * 100
    }
    
    private var gameResult: GameResult {
        if userScore > aiScore {
            return .win
        } else if userScore < aiScore {
            return .loss
        } else {
            return .tie
        }
    }
    
    private enum GameResult {
        case win, loss, tie
        
        var emoji: String {
            switch self {
            case .win: return "🏆"
            case .loss: return "😔"
            case .tie: return "🤝"
            }
        }
        
        var message: String {
            switch self {
            case .win: return "You Beat the AI!"
            case .loss: return "AI Wins This Round"
            case .tie: return "It's a Draw!"
            }
        }
        
        var color: Color {
            switch self {
            case .win: return .green
            case .loss: return .red
            case .tie: return .orange
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Result Header
                VStack(spacing: 16) {
                    Text(gameResult.emoji)
                        .font(.system(size: 80))
                    
                    Text(gameResult.message)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(gameResult.color)
                    
                    // Score Comparison
                    HStack(spacing: 40) {
                        // User Score
                        VStack(spacing: 8) {
                            Text("You")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(userScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Text(String(format: "%.0f%%", userPercentage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("VS")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        // AI Score
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                    .font(.caption)
                                Text("AI")
                            }
                            .font(.headline)
                            .foregroundColor(.secondary)
                            
                            Text("\(aiScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.indigo)
                            
                            Text(String(format: "%.0f%%", aiPercentage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // TEMPORARILY HIDDEN - Save Score Button
                    /*
                    // Save Score Button (only for logged in users)
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
                        Label("Score Saved!", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    */
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding()
                
                // AI Model Info
                if let aiModel = AIModelManager.shared.selectedModel {
                    VStack(spacing: 8) {
                        Label("AI Opponent", systemImage: "cpu")
                            .font(.headline)
                            .foregroundColor(.indigo)
                        
                        Text(aiModel.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Question by Question Comparison
                VStack(alignment: .leading, spacing: 16) {
                    Text("Round by Round")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        AIComparisonCard(
                            questionNumber: index + 1,
                            question: question,
                            userAnswer: userAnswers[index],
                            aiAnswer: aiAnswers[index]
                        )
                    }
                }
                .padding(.bottom)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Game Results")
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
        }
        .alert("Return to Menu?", isPresented: $showNewGameConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Return", role: .destructive) {
                returnToMenu()
            }
        } message: {
            Text("Are you sure you want to return to the main menu?")
        }
        .alert("Save Error", isPresented: $showSaveError) {
            Button("Try Again") {
                saveScore()
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    private func saveScore() {
        guard User.current != nil else {
            print("⚠️ No user logged in, cannot save score")
            return
        }
        
        guard !scoreSaved else {
            print("⚠️ Score already saved, preventing duplicate save")
            return
        }
        
        isSavingScore = true
        
        print("💾 Starting AI game score save: \(userScore)/\(questions.count) in \(category) (vs AI) - \(difficulty)")
        
        Task {
            do {
                // Save the user's score (not the AI's)
                try await ParseService.shared.saveGameScore(
                    score: userScore,
                    totalQuestions: questions.count,
                    category: category + " (vs AI)",
                    difficulty: difficulty,
                    timeTaken: 0 // Could track actual time if needed
                )
                
                await MainActor.run {
                    print("✅ AI game score saved successfully!")
                    isSavingScore = false
                    scoreSaved = true
                    
                    // Show success feedback
                    withAnimation(.easeInOut) {
                        // Trigger UI update to show success state
                    }
                }
            } catch {
                print("❌ Error saving AI game score: \(error)")
                await MainActor.run {
                    isSavingScore = false
                    scoreSaved = false // Allow retry
                    saveErrorMessage = "Failed to save score: \(error.localizedDescription)"
                    showSaveError = true
                }
            }
        }
    }
    
    private func returnToMenu() {
        // This will dismiss the entire navigation stack back to the root MenuView
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

// MARK: - Comparison Card
struct AIComparisonCard: View {
    let questionNumber: Int
    let question: TriviaQuestion
    let userAnswer: UserAnswer
    let aiAnswer: UserAnswer
    
    private var bothCorrect: Bool {
        userAnswer.isCorrect == true && aiAnswer.isCorrect == true
    }
    
    private var onlyUserCorrect: Bool {
        userAnswer.isCorrect == true && aiAnswer.isCorrect != true
    }
    
    private var onlyAICorrect: Bool {
        userAnswer.isCorrect != true && aiAnswer.isCorrect == true
    }
    
    private var bothWrong: Bool {
        userAnswer.isCorrect != true && aiAnswer.isCorrect != true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline)
                
                Spacer()
                
                // Result indicator
                if bothCorrect {
                    Label("Both Correct", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if onlyUserCorrect {
                    Label("You Won", systemImage: "person.fill.checkmark")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if onlyAICorrect {
                    Label("AI Won", systemImage: "cpu")
                        .font(.caption)
                        .foregroundColor(.indigo)
                } else {
                    Label("Both Wrong", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Question
            Text(question.decodedQuestion)
                .font(.subheadline)
                .lineLimit(2)
            
            Divider()
            
            // Answers comparison
            HStack(spacing: 20) {
                // User answer
                VStack(alignment: .leading, spacing: 4) {
                    Label("You", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let answer = userAnswer.selectedAnswer {
                        HStack {
                            Image(systemName: userAnswer.isCorrect == true ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(userAnswer.isCorrect == true ? .green : .red)
                                .font(.caption)
                            
                            Text(answer.htmlDecoded)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No answer")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                // AI answer
                VStack(alignment: .leading, spacing: 4) {
                    Label("AI", systemImage: "cpu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let answer = aiAnswer.selectedAnswer {
                        HStack {
                            Image(systemName: aiAnswer.isCorrect == true ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(aiAnswer.isCorrect == true ? .green : .red)
                                .font(.caption)
                            
                            Text(answer.htmlDecoded)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No answer")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Show correct answer if both wrong
            if bothWrong {
                HStack {
                    Text("Correct:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(question.decodedCorrectAnswer)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.green)
                        .lineLimit(1)
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

#Preview {
    AIResultsView(
        questions: [],
        userAnswers: [],
        aiAnswers: [],
        category: "General",
        difficulty: "Medium"
    )
}
