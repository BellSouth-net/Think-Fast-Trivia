//
//  AIGameOptionsView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI

struct AIGameOptionsView: View {
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
                    colors: [Color.indigo.opacity(0.3), Color.cyan.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .font(.system(size: 60))
                                .foregroundColor(.indigo)
                            
                            Text("Play vs AI")
                                .font(.largeTitle)
                                .bold()
                            
                            Text("Configure your game against AI")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // AI Info Card
                        if let selectedModel = AIModelManager.shared.selectedModel {
                            VStack(spacing: 8) {
                                Label("AI Opponent", systemImage: "cpu")
                                    .font(.headline)
                                    .foregroundColor(.indigo)
                                
                                Text(selectedModel.name)
                                    .font(.subheadline)
                                    .bold()
                                
                                Text(selectedModel.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Options Card
                        VStack(spacing: 20) {
                            // Number of Questions
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "number")
                                        .foregroundColor(.indigo)
                                    Text("Number of Questions: \(Int(numberOfQuestions))")
                                        .font(.headline)
                                }
                                
                                Slider(value: $numberOfQuestions, in: 5...20, step: 5)
                                    .tint(.indigo)
                                
                                HStack {
                                    Text("5")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("20")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.indigo)
                                    Text("Category")
                                        .font(.headline)
                                }
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(TriviaCategory.allCases) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.indigo)
                            }
                            
                            Divider()
                            
                            // Difficulty
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .foregroundColor(.indigo)
                                    Text("Difficulty")
                                        .font(.headline)
                                }
                                
                                Text("AI accuracy adapts to difficulty level")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
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
                                        .foregroundColor(.indigo)
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
                        Button(action: startAIGame) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start AI Game")
                                        .font(.headline)
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
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToGame) {
                AITriviaGameView(
                    questions: questions,
                    category: selectedCategory.rawValue,
                    difficulty: selectedDifficulty.rawValue
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func startAIGame() {
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
                
                // Navigate to AI game
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
    AIGameOptionsView()
}
