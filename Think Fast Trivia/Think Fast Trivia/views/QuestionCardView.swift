//
//  QuestionCardView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import SwiftUI

struct QuestionCardView: View {
    let question: TriviaQuestion
    @Binding var selectedAnswer: String?
    
    // Track selected index internally for UI
    @State private var selectedIndex: Int? = nil
    
    // Store the answers to ensure they're available
    private let answersArray: [(index: Int, original: String, decoded: String)]
    
    init(question: TriviaQuestion, selectedAnswer: Binding<String?>) {
        self.question = question
        self._selectedAnswer = selectedAnswer
        
        // Pre-compute the answers array
        self.answersArray = question.allAnswers.indices.map { index in
            (index: index,
             original: question.allAnswers[index],
             decoded: question.decodedAllAnswers[index])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Badges
            HStack {
                BadgeLabel(text: question.category,
                           systemImage: "folder.fill",
                           fg: Color.purple, bg: Color.purple.opacity(0.2))
                BadgeLabel(text: question.difficulty.capitalized,
                           systemImage: "chart.bar.fill",
                           fg: difficultyColor, bg: difficultyColor.opacity(0.2))
                Spacer()
            }

            // Question
            Text(question.decodedQuestion)
                .font(.title3).bold()
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Answer buttons - using pre-computed array from init
            VStack(spacing: 12) {
                ForEach(answersArray, id: \.index) { answer in
                    SimpleAnswerButton(
                        text: answer.decoded,
                        index: answer.index,
                        selectedIndex: $selectedIndex,
                        onTap: {
                            // Toggle selection
                            if selectedIndex == answer.index {
                                selectedIndex = nil
                                selectedAnswer = nil
                                print("❌ Deselected answer")
                            } else {
                                selectedIndex = answer.index
                                selectedAnswer = answer.original
                                
                                // Check if correct answer was selected
                                let isCorrect = answer.original == question.correctAnswer
                                print("✅ Selected: \(answer.original) - \(isCorrect ? "CORRECT!" : "WRONG")")
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .onAppear {
            print("🔄 QuestionCardView appeared: \(question.decodedQuestion.prefix(50))...")
            // Sync initial selection if any
            if let answer = selectedAnswer {
                selectedIndex = answersArray.first(where: { $0.original == answer })?.index
            }
        }
        .onChange(of: question.id) { _, _ in
            // Reset selected index when question changes
            if let answer = selectedAnswer {
                selectedIndex = answersArray.first(where: { $0.original == answer })?.index
            } else {
                selectedIndex = nil
            }
        }
    }

    private var difficultyColor: Color {
        switch question.difficulty.lowercased() {
        case "easy":   return Color.green
        case "medium": return Color.orange
        case "hard":   return Color.red
        default:       return Color.gray
        }
    }
}

// MARK: - Small helpers

private struct BadgeLabel: View {
    let text: String
    let systemImage: String
    let fg: Color
    let bg: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(8)
    }
}

// MARK: - Simple Answer Button
struct SimpleAnswerButton: View {
    let text: String
    let index: Int
    @Binding var selectedIndex: Int?
    let onTap: () -> Void
    
    private var isSelected: Bool {
        selectedIndex == index
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color(.systemGray4),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
