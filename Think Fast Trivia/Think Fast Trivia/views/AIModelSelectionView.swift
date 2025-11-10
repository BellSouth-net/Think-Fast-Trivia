//
//  AIModelSelectionView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI

struct AIModelSelectionView: View {
    @StateObject private var modelManager = AIModelManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedModelId: String = UserDefaults.standard.string(forKey: "selectedAIModelId") ?? AIModelDefinition.tinyllama.id
    @State private var showDeleteConfirmation = false
    @State private var modelToDelete: AIModelDefinition?
    @State private var isLoadingModel = false
    @State private var loadError: String?
    @State private var showError = false
    
    let onModelSelected: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - darker for better contrast
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.14),
                        Color(red: 0.18, green: 0.18, blue: 0.21)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "cpu")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Select AI Opponent")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("Choose an AI model to play against")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Model Selection
                        VStack(spacing: 16) {
                            ForEach(AIModelDefinition.availableModels, id: \.id) { model in
                                AIModelCard(
                                    model: model,
                                    isSelected: selectedModelId == model.id,
                                    isDownloaded: AIModelManager.isModelDownloaded(model),
                                    isDownloading: modelManager.isModelDownloading(model),
                                    downloadProgress: modelManager.isModelDownloading(model) ? modelManager.downloadProgress : nil,
                                    onSelect: {
                                        selectModel(model)
                                    },
                                    onDelete: {
                                        modelToDelete = model
                                        showDeleteConfirmation = true
                                    }
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedModelId)
                                .disabled(modelManager.isDownloading && !modelManager.isModelDownloading(model))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("AI Opponent Info", systemImage: "info.circle.fill")
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            Text("• Smaller models (1-2GB) run faster but may be less accurate")
                            Text("• Larger models (3-4GB) are smarter but take longer to think")
                            Text("• Models are downloaded once and stored locally")
                            Text("• AI difficulty adapts based on question difficulty")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Start Game Button
                        Button(action: startGameWithAI) {
                            HStack {
                                if isLoadingModel {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Loading Model...")
                                } else if modelManager.isDownloading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Downloading Model...")
                                } else if !AIModelManager.isModelDownloaded(getSelectedModel()) {
                                    Image(systemName: "arrow.down.circle")
                                    Text("Download Model First")
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start Game vs AI")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: buttonGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoadingModel || modelManager.isDownloading)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                
                // Download Progress Overlay
                if let progress = modelManager.downloadProgress, modelManager.isDownloading {
                    VStack(spacing: 20) {
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                            .tint(.purple)
                        
                        Text("Downloading Model...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(FormatUtils.formatProgress(progress))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                    )
                    .shadow(radius: 10)
                }
            }
            .onAppear {
                // Let ModelManager know modal is showing (hides global progress)
                modelManager.isModalShowing = true
            }
            .onDisappear {
                // Modal closed, allow global progress to show if still downloading
                modelManager.isModalShowing = false
            }
            .navigationTitle("AI Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Model", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    modelToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteModel()
                }
            } message: {
                if let model = modelToDelete {
                    Text("Delete \(model.name)? This will free up \(AIModelManager.getModelSize(model)) of storage.")
                }
            }
            .alert(alertTitle, isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(loadError ?? "An error occurred")
            }
        }
    }
    
    private func getSelectedModel() -> AIModelDefinition {
        AIModelDefinition.availableModels.first { $0.id == selectedModelId } ?? AIModelDefinition.tinyllama
    }
    
    private var buttonGradientColors: [Color] {
        if isLoadingModel || modelManager.isDownloading {
            return [Color.orange, Color.orange.opacity(0.7)]
        } else if !AIModelManager.isModelDownloaded(getSelectedModel()) {
            return [Color.purple, Color.blue]
        } else if modelManager.isLoaded && modelManager.selectedModel?.id == selectedModelId {
            return [Color.green, Color.blue]
        } else {
            return [Color.purple, Color.purple.opacity(0.7)]
        }
    }
    
    private var alertTitle: String {
        if let error = loadError {
            if error.contains("downloaded successfully") {
                return "Success"
            } else if error.contains("needs to be downloaded") {
                return "Model Not Downloaded"
            } else if error.contains("Download failed") {
                return "Download Failed"
            }
        }
        return "Notice"
    }
    
    private func selectModel(_ model: AIModelDefinition) {
        // Don't allow selection if another model is downloading
        guard !modelManager.isDownloading || modelManager.isModelDownloading(model) else {
            loadError = "Please wait for the current download to complete before selecting another model."
            showError = true
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedModelId = model.id
            UserDefaults.standard.set(model.id, forKey: "selectedAIModelId")
        }
        
        // Configure the model manager
        modelManager.configure(model)
        
        // If model is not downloaded, start download
        if !AIModelManager.isModelDownloaded(model) {
            Task {
                do {
                    try await modelManager.prepareModel { progress in
                        // Progress is handled by published property
                    }
                } catch {
                    await MainActor.run {
                        loadError = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
    
    private func startGameWithAI() {
        let model = getSelectedModel()
        
        // If model is not downloaded, start download first
        guard AIModelManager.isModelDownloaded(model) else {
            loadError = "Model '\(model.name)' needs to be downloaded first (\(model.sizeGB)). Tap the model card to start downloading."
            showError = true
            
            // Automatically start the download
            modelManager.configure(model)
            Task {
                do {
                    try await modelManager.prepareModel { progress in
                        // Progress is handled by published property
                    }
                    // After download completes, notify user
                    await MainActor.run {
                        loadError = "Model downloaded successfully! Tap 'Start Game vs AI' again to begin."
                        showError = true
                    }
                } catch {
                    await MainActor.run {
                        loadError = "Download failed: \(error.localizedDescription). Please try again."
                        showError = true
                    }
                }
            }
            return
        }
        
        isLoadingModel = true
        
        Task {
            do {
                // Configure and prepare the model if not already loaded
                if !modelManager.isLoaded || modelManager.selectedModel?.id != model.id {
                    modelManager.configure(model)
                    try await modelManager.prepareModel()
                }
                
                await MainActor.run {
                    isLoadingModel = false
                    dismiss()
                    onModelSelected()
                }
            } catch {
                await MainActor.run {
                    isLoadingModel = false
                    // More informative error messages based on the error type
                    if error.localizedDescription.contains("model") {
                        loadError = "Failed to load the AI model. Please ensure the model is downloaded and try again."
                    } else {
                        loadError = "Error: \(error.localizedDescription)"
                    }
                    showError = true
                }
            }
        }
    }
    
    private func deleteModel() {
        guard let model = modelToDelete else { return }
        
        do {
            try modelManager.deleteModel(model)
            modelToDelete = nil
        } catch {
            loadError = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - AI Model Card
struct AIModelCard: View {
    let model: AIModelDefinition
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double?
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var modelManager = AIModelManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    // Show if downloaded
                    if isDownloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color.green)
                            .font(.caption)
                    }
                    
                    // Show if currently loaded
                    if isSelected && modelManager.isLoaded && modelManager.selectedModel?.id == model.id {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color.orange)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Show file size
                    Text("• \(isDownloaded ? AIModelManager.getModelSize(model) : model.sizeGB)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if isDownloading, let progress = downloadProgress {
                    ProgressView(value: progress)
                        .tint(Color.purple)
                    
                    Text("\(FormatUtils.formatProgress(progress)) downloaded")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Delete button if downloaded
            if isDownloaded && !isDownloading {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(Color.red.opacity(0.8))
                        .font(.system(size: 22))
                }
                .padding(.trailing, 8)
            }
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(
                    isSelected
                    ? Color.purple
                    : Color.white.opacity(0.4)
                )
                .font(.system(size: 20))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected
                    ? Color.purple.opacity(0.2)
                    : Color.white.opacity(0.05)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected
                    ? Color.purple.opacity(0.5)
                    : Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onSelect()
            }
        }
        .opacity(modelManager.isDownloading && !isDownloading ? 0.6 : 1.0)
    }
}

#Preview {
    AIModelSelectionView(onModelSelected: {})
}
