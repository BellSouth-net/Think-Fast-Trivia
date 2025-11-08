//
//  ResultsView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import SwiftUI

struct ResultsView: View {
    let questions: [TriviaQuestion]
    let userAnswers: [UserAnswer]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showNewGameConfirmation = false
    
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
                        Text("New Game")
                    }
                }
            }
        }
        .alert("Start New Game?", isPresented: $showNewGameConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("New Game", role: .destructive) {
                // Dismiss all the way back to the root
                resetToMainMenu()
            }
        } message: {
            Text("Are you sure you want to start a new game? Your current progress will be lost.")
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
