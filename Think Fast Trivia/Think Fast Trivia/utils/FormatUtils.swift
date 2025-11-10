//
//  FormatUtils.swift
//  Think Fast Trivia
//
//  Simple formatting utilities used across the app
//

import Foundation

enum FormatUtils {
    
    // MARK: - File Size Formatting
    
    /// Format bytes into human-readable string (e.g., "1.5 GB")
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Format bytes from optional Int64
    static func formatFileSize(_ bytes: Int64?) -> String? {
        guard let bytes = bytes else { return nil }
        return formatFileSize(bytes)
    }
    
    // MARK: - Time Formatting
    
    /// Format seconds into MM:SS format for game timer
    static func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Percentage Formatting
    
    /// Format a decimal progress value (0.0-1.0) as percentage string
    static func formatProgress(_ progress: Double) -> String {
        return "\(Int(progress * 100))%"
    }
    
    /// Format score percentage
    static func formatPercentage(_ value: Double) -> String {
        return String(format: "%.0f%%", value)
    }
}
