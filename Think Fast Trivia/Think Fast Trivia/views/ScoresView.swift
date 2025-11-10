//
//  ScoresView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct ScoresView: View {
    @State private var scores: [GameScore] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading scores...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else if scores.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Games Played Yet")
                        .font(.title2)
                        .bold()
                    
                    Text("Play your first game to see your scores here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Card
                        VStack(spacing: 16) {
                            Text("Score Summary")
                                .font(.title2)
                                .bold()
                            
                            HStack(spacing: 30) {
                                VStack {
                                    Text("\(scores.count)")
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.purple)
                                    Text("Total Games")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text(String(format: "%.1f", averageScore))
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("Avg Score")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text(String(format: "%.0f%%", averagePercentage))
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.green)
                                    Text("Avg Accuracy")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Game History
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Game History")
                                .font(.title3)
                                .bold()
                                .padding(.horizontal)
                            
                            ForEach(scores, id: \.objectId) { score in
                                ScoreCard(score: score)
                            }
                        }
                        .padding(.bottom)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Your Scores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { loadScores() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadScores()
        }
        .alert("Error Loading Scores", isPresented: $showError) {
            Button("Try Again") {
                loadScores()
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var averageScore: Double {
        guard !scores.isEmpty else { return 0 }
        let total = scores.compactMap { $0.score }.reduce(0, +)
        return Double(total) / Double(scores.count)
    }
    
    private var averagePercentage: Double {
        guard !scores.isEmpty else { return 0 }
        let total = scores.compactMap { $0.percentage }.reduce(0, +)
        return total / Double(scores.count)
    }
    
    private func loadScores() {
        // Reset states
        isLoading = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                // Check if user is logged in first
                guard User.current != nil else {
                    await MainActor.run {
                        self.errorMessage = "You must be logged in to view scores"
                        self.showError = true
                        self.isLoading = false
                    }
                    return
                }
                
                print("📊 Loading scores for current user...")
                let fetchedScores = try await ParseService.shared.fetchUserScores()
                
                await MainActor.run {
                    print("📊 Successfully loaded \(fetchedScores.count) scores")
                    self.scores = fetchedScores
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading scores: \(error)")
                    self.errorMessage = "Failed to load scores: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct ScoreCard: View {
    let score: GameScore
    
    private var scoreEmoji: String {
        guard let percentage = score.percentage else { return "📝" }
        switch percentage {
        case 90...100: return "🏆"
        case 75..<90: return "🎉"
        case 60..<75: return "👍"
        case 40..<60: return "😐"
        default: return "📚"
        }
    }
    
    private var formattedDate: String {
        guard let date = score.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var formattedTime: String {
        guard let seconds = score.timeTaken else { return "" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        HStack {
            // Emoji and Score
            HStack(spacing: 12) {
                Text(scoreEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(score.score ?? 0)/\(score.totalQuestions ?? 0)")
                        .font(.headline)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Details
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", score.percentage ?? 0))
                    .font(.headline)
                    .foregroundColor(percentageColor)
                
                HStack(spacing: 4) {
                    if let category = score.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let difficulty = score.difficulty {
                        Text(difficulty.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if !formattedTime.isEmpty {
                    Text("⏱ \(formattedTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var percentageColor: Color {
        guard let percentage = score.percentage else { return .gray }
        switch percentage {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private var difficultyColor: Color {
        switch score.difficulty?.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        ScoresView()
    }
}
