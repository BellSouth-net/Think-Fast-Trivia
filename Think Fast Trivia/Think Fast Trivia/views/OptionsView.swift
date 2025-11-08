//
//  OptionsView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import SwiftUI

struct OptionsView: View {
    @State private var numberOfQuestions: Double = 10
    @State private var selectedCategory: TriviaCategory = .any
    @State private var selectedDifficulty: TriviaDifficulty = .any
    @State private var selectedType: TriviaQuestionType = .any
    @State private var isLoading = false
    @State private var navigateToGame = false
    @State private var questions: [TriviaQuestion] = []
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let triviaService = TriviaService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("Think Fast Trivia")
                                .font(.largeTitle)
                                .bold()
                            
                            Text("Configure your game settings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Options Card
                        VStack(spacing: 20) {
                            // Number of Questions
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "number")
                                        .foregroundColor(.purple)
                                    Text("Number of Questions: \(Int(numberOfQuestions))")
                                        .font(.headline)
                                }
                                
                                Slider(value: $numberOfQuestions, in: 5...50, step: 5)
                                    .tint(.purple)
                                
                                HStack {
                                    Text("5")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("50")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.purple)
                                    Text("Category")
                                        .font(.headline)
                                }
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(TriviaCategory.allCases) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.purple)
                            }
                            
                            Divider()
                            
                            // Difficulty
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .foregroundColor(.purple)
                                    Text("Difficulty")
                                        .font(.headline)
                                }
                                
                                Picker("Difficulty", selection: $selectedDifficulty) {
                                    ForEach(TriviaDifficulty.allCases) { difficulty in
                                        Text(difficulty.rawValue).tag(difficulty)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            Divider()
                            
                            // Question Type
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.purple)
                                    Text("Question Type")
                                        .font(.headline)
                                }
                                
                                Picker("Type", selection: $selectedType) {
                                    ForEach(TriviaQuestionType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Start Button
                        Button(action: startGame) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start Game")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                TriviaGameView(questions: questions)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func startGame() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                questions = try await triviaService.fetchQuestions(
                    amount: Int(numberOfQuestions),
                    category: selectedCategory,
                    difficulty: selectedDifficulty,
                    type: selectedType
                )
                
                // Navigate to game
                navigateToGame = true
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    OptionsView()
}
