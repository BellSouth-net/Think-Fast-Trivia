//
//  AIModelManager.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit
import os.log

@MainActor
final class AIModelManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AIModelManager()
    
    // MARK: - Published Properties
    @Published private(set) var isLoaded: Bool = false
    @Published private(set) var isPreparing: Bool = false
    @Published private(set) var downloadProgress: Double? = nil
    @Published var selectedModel: AIModelDefinition?
    @Published var isDownloading: Bool = false
    @Published var isModalShowing: Bool = false  // Track if model selection modal is showing
    
    // MARK: - Private Properties
    private var config: Config?
    private var runtime: AIRuntime?
    private let fileStore = FileStore()
    private let log = Logger(subsystem: "ThinkFastTrivia", category: "AIModelManager")
    private var downloadingModelId: String? = nil  // Track which model is currently downloading
    private var downloadTask: Task<Void, Error>? = nil  // Track current download task
    
    private init() {}
    
    // MARK: - Public API
    
    /// Configure the model manager with a specific model
    func configure(_ model: AIModelDefinition) {
        // Clean up existing model if switching to a different one
        if isLoaded && config?.modelDefinition.id != model.id {
            runtime?.cancel()
            runtime = nil
            isLoaded = false
            downloadProgress = nil
        }
        
        self.config = Config(modelDefinition: model)
        self.selectedModel = model
    }
    
    /// Prepare the model (download if needed and load)
    func prepareModel(progress: @escaping (Double) -> Void = { _ in }) async throws {
        guard let config = config else { throw AIError.notConfigured }
        
        if isLoaded { return } // Already loaded
        
        // Check if we're already downloading this model
        if let downloadingId = downloadingModelId, downloadingId == config.modelDefinition.id {
            log.info("Model \(config.modelDefinition.name) is already downloading, skipping duplicate request")
            return
        }
        
        // Cancel any existing download task for a different model
        if downloadTask != nil {
            log.info("Cancelling previous download task")
            downloadTask?.cancel()
            downloadTask = nil
            downloadingModelId = nil
            isDownloading = false
            downloadProgress = nil
        }
        
        isPreparing = true
        defer { 
            isPreparing = false
            downloadingModelId = nil
            downloadTask = nil
        }
        
        // Track which model we're downloading
        downloadingModelId = config.modelDefinition.id
        
        // Create download task
        downloadTask = Task {
            // 1) Ensure file exists (download if needed)
            isDownloading = true
            downloadProgress = 0.0
            
            let localURL = try await fileStore.ensureFile(
                remoteURL: URL(string: config.modelDefinition.huggingFaceURL)!,
                filename: config.modelDefinition.filename,
                progress: { [weak self] p in
                    Task { @MainActor in
                        self?.downloadProgress = p
                        progress(p)
                    }
                }
            )
            
            isDownloading = false
            downloadProgress = nil
            
            // 2) Create runtime if needed
            if runtime == nil {
                runtime = config.runtimeFactory()
            }
            guard let runtime = runtime else { throw AIError.runtimeUnavailable }
            
            // 3) Load the model
            if !isLoaded {
                try await runtime.loadModel(at: localURL, context: config.contextLength)
                isLoaded = true
            }
        }
        
        try await downloadTask?.value
    }
    
    /// Ensure model is ready, then generate answer
    func ensureAndGenerateAnswer(
        question: String,
        category: String,
        difficulty: String,
        correctAnswer: String,
        incorrectAnswers: [String]
    ) async throws -> (answer: String, confidence: Float, thinkingTime: Double) {
        if !isLoaded {
            try await prepareModel()
        }
        return try await generateAnswer(
            question: question,
            category: category,
            difficulty: difficulty,
            correctAnswer: correctAnswer,
            incorrectAnswers: incorrectAnswers
        )
    }
    
    /// Generate AI answer for trivia question
    private func generateAnswer(
        question: String,
        category: String,
        difficulty: String,
        correctAnswer: String,
        incorrectAnswers: [String]
    ) async throws -> (answer: String, confidence: Float, thinkingTime: Double) {
        guard let config = config else { throw AIError.notConfigured }
        guard let runtime = runtime, isLoaded else { throw AIError.modelNotLoaded }
        
        let params = config.generationParams
        
        return try await runtime.generateAnswer(
            question: question,
            category: category,
            difficulty: difficulty,
            correctAnswer: correctAnswer,
            incorrectAnswers: incorrectAnswers,
            params: params
        )
    }
    
    /// Unload current model
    func unloadModel() {
        runtime?.cancel()
        runtime = nil
        isLoaded = false
        selectedModel = nil
        downloadProgress = nil
    }
    
    /// Cancel current AI operation (for background handling)
    func cancelCurrentOperation() {
        runtime?.cancel()
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadProgress = nil
    }
    
    /// Check if model is downloaded
    static func isModelDownloaded(_ model: AIModelDefinition) -> Bool {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelPath = documentsDir.appendingPathComponent(model.filename)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    /// Delete model file
    func deleteModel(_ model: AIModelDefinition) throws {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelPath = documentsDir.appendingPathComponent(model.filename)
        
        // Unload if this is the current model
        if selectedModel?.id == model.id {
            unloadModel()
        }
        
        // Delete file
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
        }
    }
    
    /// Get model file size
    static func getModelSize(_ model: AIModelDefinition) -> String {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelPath = documentsDir.appendingPathComponent(model.filename)
        
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: modelPath.path),
              let fileSize = attrs[.size] as? Int64 else {
            return model.sizeGB
        }
        
        return FormatUtils.formatFileSize(fileSize)
    }
    
    /// Check if a specific model is currently downloading
    func isModelDownloading(_ model: AIModelDefinition) -> Bool {
        return downloadingModelId == model.id && isDownloading
    }
}

// MARK: - Configuration
extension AIModelManager {
    struct Config {
        let modelDefinition: AIModelDefinition
        
        // Model loading parameters
        var contextLength: Int {
            modelDefinition.contextLength
        }
        
        // Generation parameters for trivia
        var generationParams: GenerationParams {
            GenerationParams(
                temperature: 0.7,  // Some randomness for realistic play
                topP: 0.9,
                maxTokens: 50  // Short answers only
            )
        }
        
        // Runtime factory - allows switching between different backends if needed
        var runtimeFactory: () -> AIRuntime = { AIManager() }
    }
}

// MARK: - File Store
private final class FileStore {
    private let log = Logger(subsystem: "ThinkFastTrivia", category: "FileStore")
    private var cancellable: AnyCancellable?
    
    private var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func ensureFile(
        remoteURL: URL,
        filename: String,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let destination = documentsDir.appendingPathComponent(filename)
        
        // If file exists, return it
        if FileManager.default.fileExists(atPath: destination.path) {
            log.info("Model file already exists: \(filename)")
            progress(1.0)
            return destination
        }
        
        // Download file using the efficient DownloadManager
        log.info("Downloading model: \(filename)")
        
        // Subscribe to progress updates
        let downloadManager = DownloadManager.shared
        cancellable = downloadManager.$downloadProgress
            .sink { progressValue in
                progress(progressValue)
            }
        
        defer { 
            cancellable?.cancel()
            cancellable = nil
        }
        
        let downloadedURL = try await downloadManager.downloadFile(from: remoteURL, to: destination)
        
        return downloadedURL
    }
    
    private func download(
        from remoteURL: URL,
        to localURL: URL,
        progress: @escaping (Double) -> Void
    ) async throws {
        let tempURL = localURL.appendingPathExtension("part")
        
        // Resume support
        var request = URLRequest(url: remoteURL)
        var startFrom: Int64 = 0
        
        if FileManager.default.fileExists(atPath: tempURL.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
               let size = attrs[.size] as? Int64 {
                startFrom = size
                if startFrom > 0 {
                    request.addValue("bytes=\(startFrom)-", forHTTPHeaderField: "Range")
                    log.info("Resuming download from byte: \(startFrom)")
                }
            }
        }
        
        print("🔗 Downloading from: \(remoteURL.absoluteString)")
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ No HTTP response received")
            throw AIError.networkError
        }
        
        print("📡 HTTP Status Code: \(httpResponse.statusCode)")
        
        guard (200...206).contains(httpResponse.statusCode) else {
            print("❌ Download failed with status: \(httpResponse.statusCode)")
            throw AIError.networkError
        }
        
        let totalSize: Int64? = {
            if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let size = Int64(contentLength) {
                let total = startFrom + size
                print("📦 Total file size: \(FormatUtils.formatFileSize(total)) (Content-Length: \(contentLength))")
                return total
            }
            print("⚠️ No Content-Length header received - progress tracking unavailable")
            return nil
        }()
        
        // Create directory if needed
        try FileManager.default.createDirectory(at: tempURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        
        // Create file handle
        let handle: FileHandle
        if FileManager.default.fileExists(atPath: tempURL.path) {
            handle = try FileHandle(forWritingTo: tempURL)
            try handle.seekToEnd()
        } else {
            FileManager.default.createFile(atPath: tempURL.path, contents: nil)
            handle = try FileHandle(forWritingTo: tempURL)
        }
        
        var written: Int64 = startFrom
        
        // Buffer bytes into Data, write periodically (64 KB chunks)
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)
        
        for try await byte in bytes {            // 'byte' is UInt8
            buffer.append(byte)                  // append to Data buffer
            if buffer.count >= 64 * 1024 {
                try handle.write(contentsOf: buffer)
                written += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                
                if let t = totalSize, t > 0 {
                    progress(Double(written) / Double(t))
                }
            }
        }
        
        // flush any remainder
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
            written += Int64(buffer.count)
            if let t = totalSize, t > 0 {
                progress(Double(written) / Double(t))
            }
        }
        
        try handle.close()
        
        // Move temp file to final destination
        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        log.info("Download complete: \(localURL.lastPathComponent)")
    }
}
