//
//  DownloadManager.swift
//  Think Fast Trivia
//
//  Efficient download manager using URLSession download tasks
//

import Foundation
import os.log
import Combine

final class DownloadManager: NSObject, ObservableObject {
    @MainActor static let shared = DownloadManager()
    
    @MainActor @Published var downloadProgress: Double = 0
    private var downloadTask: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private let log = Logger(subsystem: "ThinkFastTrivia", category: "DownloadManager")
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    override private init() {
        super.init()
    }
    
    private var destinationURL: URL?
    
    func downloadFile(from url: URL, to destinationURL: URL) async throws -> URL {
        print("🚀 Starting optimized download from: \(url)")
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("✅ File already exists at destination")
            await MainActor.run {
                downloadProgress = 1.0
            }
            return destinationURL
        }
        
        self.destinationURL = destinationURL
        await MainActor.run {
            downloadProgress = 0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Use delegate-based download task (no completion handler)
            let task = session.downloadTask(with: url)
            self.downloadTask = task
            task.resume()
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        continuation = nil
        Task { @MainActor in
            downloadProgress = 0
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // This is called when download completes
        print("✅ Download finished to temporary location: \(location)")
        
        guard let destinationURL = self.destinationURL else {
            continuation?.resume(throwing: AIError.networkError)
            return
        }
        
        do {
            // Move file to destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("✅ File moved to: \(destinationURL.lastPathComponent)")
            
            Task { @MainActor in
                self.downloadProgress = 1.0
            }
            
            continuation?.resume(returning: destinationURL)
            continuation = nil
            self.destinationURL = nil
        } catch {
            print("❌ Failed to move file: \(error)")
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        Task { @MainActor in
            self.downloadProgress = progress
            if Int(progress * 100) % 10 == 0 {  // Log every 10%
                print("📊 Download progress: \(Int(progress * 100))% (\(FormatUtils.formatFileSize(totalBytesWritten))/\(FormatUtils.formatFileSize(totalBytesExpectedToWrite)))")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print("🔀 Following redirect to: \(request.url?.absoluteString ?? "unknown")")
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ Download task error: \(error.localizedDescription)")
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
