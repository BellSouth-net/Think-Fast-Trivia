//
//  AIManager.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import Foundation

// Bridge to the LlamaRunner for AI trivia responses
final class AIManager: AIRuntime, @unchecked Sendable {
    private var runner: LlamaRunner?
    private let queue = DispatchQueue(label: "com.thinkfast.ai", qos: .userInitiated)
    private var currentModelId: String?
    
    func loadModel(at localURL: URL, context: Int) async throws {
        // Clean up any existing runner
        runner?.cleanup()
        
        // Detect model type from filename
        let filename = localURL.lastPathComponent.lowercased()
        if filename.contains("tinyllama") {
            currentModelId = "tinyllama"
        } else if filename.contains("qwen") {
            currentModelId = "qwen"
        } else if filename.contains("phi") {
            currentModelId = "phi3"
        } else if filename.contains("gemma") {
            currentModelId = "gemma"
        } else {
            currentModelId = nil
        }
        
        // Load model on background queue
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                let newRunner = LlamaRunner(modelPath: localURL.path, contextSize: Int32(context))
                
                if newRunner != nil {
                    self?.runner = newRunner
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AIError.modelLoadFailed)
                }
            }
        }
    }
    
    func generateAnswer(
        question: String,
        category: String,
        difficulty: String,
        correctAnswer: String,
        incorrectAnswers: [String],
        params: GenerationParams
    ) async throws -> (answer: String, confidence: Float, thinkingTime: Double) {
        guard let runner = runner else {
            throw AIError.modelNotLoaded
        }
        
        let startTime = Date()
        
        // Simple prompt for fast trivia answers
        let systemPrompt = """
        Answer the trivia question promptly, your response should be a the number of the answer AND the answer text. No explanations.
        """
        
        let allAnswers = incorrectAnswers + [correctAnswer]
        let shuffledAnswers = allAnswers.shuffled()
        let answerOptions = shuffledAnswers.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        
        let userPrompt = """
        Question: \(question)
        
        Options:
        \(answerOptions)
        
        Your answer (number and text):
        """
        
        // Format prompt based on model type
        let fullPrompt = formatPromptForModel(systemPrompt: systemPrompt, userPrompt: userPrompt)
        
        // Generate response
        let response: String = try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if let aiResponse = runner.generateResponse(
                    forPrompt: fullPrompt,
                    temperature: params.temperature,
                    topP: params.topP,
                    maxTokens: Int32(params.maxTokens)
                ) {
                    continuation.resume(returning: aiResponse)
                } else {
                    continuation.resume(throwing: AIError.generationFailed)
                }
            }
        }
        
        // Parse the AI's answer
        let selectedAnswer = parseAIAnswer(response, from: shuffledAnswers)
        
        // Calculate thinking time (simulate human-like delay)
        let thinkingTime = Date().timeIntervalSince(startTime)
        
        // Calculate confidence based on difficulty and correctness
        let isCorrect = selectedAnswer == correctAnswer
        let confidence = calculateConfidence(difficulty: difficulty, isCorrect: isCorrect)
        
        return (answer: selectedAnswer, confidence: confidence, thinkingTime: thinkingTime)
    }
    
    private func parseAIAnswer(_ response: String, from options: [String]) -> String {
        // Clean the response by removing chat template tokens
        var cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common chat template tokens
        let tokensToRemove = [
            "<|im_end|>", "<|im_start|>", "<|end|>", "<|start|>",
            "<end_of_turn>", "<start_of_turn>", "<|assistant|>",
            "<|user|>", "<|system|>", "assistant:", "Assistant:",
            "model:", "Model:"
        ]
        
        for token in tokensToRemove {
            cleanResponse = cleanResponse.replacingOccurrences(of: token, with: "")
        }
        
        // Trim again after removing tokens
        cleanResponse = cleanResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🤖 Cleaned AI response: '\(cleanResponse)'")
        
        // Check if response starts with a number (1-4)
        if let firstChar = cleanResponse.first, firstChar.isNumber {
            let index = Int(String(firstChar)) ?? 0
            if index > 0 && index <= options.count {
                print("✅ AI selected option \(index): \(options[index - 1])")
                return options[index - 1]
            }
        }
        
        // Otherwise try to match the text
        for option in options {
            if cleanResponse.localizedCaseInsensitiveContains(option) {
                print("✅ AI selected by text match: \(option)")
                return option
            }
        }
        
        // Default to random option if parsing fails (more realistic than always first)
        let randomIndex = Int.random(in: 0..<options.count)
        print("⚠️ AI response parsing failed, selecting random option: \(options[randomIndex])")
        return options[randomIndex]
    }
    
    private func calculateConfidence(difficulty: String, isCorrect: Bool) -> Float {
        // Simulate AI confidence based on difficulty and correctness
        switch difficulty.lowercased() {
        case "easy":
            return isCorrect ? Float.random(in: 0.85...0.95) : Float.random(in: 0.60...0.75)
        case "medium":
            return isCorrect ? Float.random(in: 0.70...0.85) : Float.random(in: 0.45...0.60)
        case "hard":
            return isCorrect ? Float.random(in: 0.55...0.70) : Float.random(in: 0.30...0.45)
        default:
            return 0.5
        }
    }
    
    private func formatPromptForModel(systemPrompt: String, userPrompt: String) -> String {
        // Format based on detected model type
        switch currentModelId {
        case "tinyllama":
            // TinyLlama uses simple User/Assistant format
            return """
            You are a helpful assistant. Answer concisely.
            
            User: \(userPrompt)
            Assistant:
            """
            
        case "qwen":
            // Qwen 2.5 uses ChatML format
            return """
            <|im_start|>system
            \(systemPrompt)
            <|im_end|>
            <|im_start|>user
            \(userPrompt)
            <|im_end|>
            <|im_start|>assistant
            """
            
        case "phi3":
            // Phi-3 uses its own format
            return """
            <|system|>
            \(systemPrompt)<|end|>
            <|user|>
            \(userPrompt)<|end|>
            <|assistant|>
            """
            
        case "gemma":
            // Gemma uses a simpler format
            return """
            <start_of_turn>user
            \(systemPrompt)
            
            \(userPrompt)<end_of_turn>
            <start_of_turn>model
            """
            
        default:
            // Default to ChatML format (works for many models)
            return """
            <|im_start|>system
            \(systemPrompt)
            <|im_end|>
            <|im_start|>user
            \(userPrompt)
            <|im_end|>
            <|im_start|>assistant
            """
        }
    }
    
    func cancel() {
        // TODO: Implement cancellation if needed
    }
    
    deinit {
        runner?.cleanup()
    }
}

// MARK: - AI Model Definitions (Smaller models for faster responses)
struct AIModelDefinition {
    let id: String
    let name: String
    let huggingFaceURL: String
    let filename: String
    let contextLength: Int
    let description: String
    let sizeGB: String
}

extension AIModelDefinition {
    // Smaller models optimized for trivia (< 5B parameters)
    
    // Commented out for now - not using these models
    /*
    static let phi3Mini = AIModelDefinition(
        id: "phi3-mini",
        name: "Phi-3 Mini 3.8B",
        huggingFaceURL: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
        filename: "Phi-3-mini-4k-instruct-q4.gguf",
        contextLength: 256,
        description: "Fast, efficient 3.8B model",
        sizeGB: "2.2 GB"
    )
    
    static let gemma2B = AIModelDefinition(
        id: "gemma-2b",
        name: "Gemma 2B",
        huggingFaceURL: "https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q4_k_m.gguf",
        filename: "gemma-2b-it-q4_k_m.gguf",
        contextLength: 256,
        description: "Google's compact 2B model",
        sizeGB: "1.5 GB"
    )
    */
    
    static let qwen2_5_0_5B = AIModelDefinition(
        id: "qwen-0.5b",
        name: "Qwen 2.5 0.5B",
        huggingFaceURL: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
        filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
        contextLength: 256,
        description: "Ultra-fast 0.5B model - Lightning quick responses",
        sizeGB: "0.4 GB"
    )
    
    static let tinyllama = AIModelDefinition(
        id: "tinyllama",
        name: "TinyLlama 1.1B",
        huggingFaceURL: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
        filename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
        contextLength: 256,
        description: "Fast 1.1B model",
        sizeGB: "0.7 GB"
    )
    
    static let qwen2_5_3B = AIModelDefinition(
        id: "qwen2.5-3b",
        name: "Qwen 2.5 3B",
        huggingFaceURL: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
        filename: "qwen2.5-3b-instruct-q4_k_m.gguf",
        contextLength: 256,
        description: "Balanced 3B model",
        sizeGB: "2.0 GB"
    )
    
    // Available models - Qwen 0.5B first for fastest responses
    static let availableModels = [qwen2_5_0_5B, tinyllama, qwen2_5_3B]
}

// MARK: - Errors
enum AIError: LocalizedError {
    case notConfigured
    case runtimeUnavailable
    case modelNotLoaded
    case modelLoadFailed
    case generationFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "AI model is not configured. Please select a model first."
        case .runtimeUnavailable: return "AI runtime is unavailable. Please restart the app."
        case .modelNotLoaded: return "AI model is not loaded yet. Please wait for it to load or try selecting it again."
        case .modelLoadFailed: return "Failed to load AI model. The model file may be corrupted. Try deleting and re-downloading it."
        case .generationFailed: return "Failed to generate AI response. Please try again."
        case .networkError: return "Network error while downloading model. Please check your internet connection and try again."
        }
    }
}

// MARK: - Runtime Protocol
protocol AIRuntime {
    func loadModel(at localURL: URL, context: Int) async throws
    func generateAnswer(
        question: String,
        category: String,
        difficulty: String,
        correctAnswer: String,
        incorrectAnswers: [String],
        params: GenerationParams
    ) async throws -> (answer: String, confidence: Float, thinkingTime: Double)
    func cancel()
}

// MARK: - Generation Parameters
struct GenerationParams {
    var temperature: Float = 0.7  // Some randomness for realistic play
    var topP: Float = 0.9
    var maxTokens: Int = 50  // Short answers only
}
