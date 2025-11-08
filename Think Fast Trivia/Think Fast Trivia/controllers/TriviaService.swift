//
//  TriviaService.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import Foundation

class TriviaService {
    private let baseURL = "https://opentdb.com/api.php"
    
    /// Fetches trivia questions based on user options
    func fetchQuestions(
        amount: Int,
        category: TriviaCategory,
        difficulty: TriviaDifficulty,
        type: TriviaQuestionType
    ) async throws -> [TriviaQuestion] {
        
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "amount", value: "\(amount)")
        ]
        
        // Add optional parameters if not "any"
        if let categoryValue = category.apiValue {
            queryItems.append(URLQueryItem(name: "category", value: categoryValue))
        }
        
        if let difficultyValue = difficulty.apiValue {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficultyValue))
        }
        
        if let typeValue = type.apiValue {
            queryItems.append(URLQueryItem(name: "type", value: typeValue))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        print("🌐 Fetching trivia from: \(url.absoluteString)")
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Decode the response
        let triviaResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)
        
        // Check for API error codes
        if !triviaResponse.isSuccess {
            throw TriviaAPIError.apiError(triviaResponse.errorMessage ?? "Unknown error")
        }
        
        print("✅ Successfully fetched \(triviaResponse.results.count) questions")
        
        return triviaResponse.results
    }
}

// MARK: - Custom Errors
enum TriviaAPIError: LocalizedError {
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        }
    }
}
