//
//  TriviaModels.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/8/25.
//

import Foundation

// MARK: - API Response
struct TriviaResponse: Codable {
    let responseCode: Int
    let results: [TriviaQuestion]
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
    
    var isSuccess: Bool {
        responseCode == 0
    }
    
    var errorMessage: String? {
        switch responseCode {
        case 0: return nil
        case 1: return "Not enough questions available for your query."
        case 2: return "Invalid parameters in request."
        case 3: return "Session token not found."
        case 4: return "Session token exhausted. Please start a new game."
        case 5: return "Rate limit exceeded. Please wait a moment."
        default: return "Unknown error occurred."
        }
    }
}

// MARK: - Trivia Question
struct TriviaQuestion: Codable, Identifiable, Hashable, Equatable {
    let id = UUID()
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    // Store shuffled answers once
    private var _shuffledAnswers: [String]?
    
    enum CodingKeys: String, CodingKey {
        case category, type, difficulty, question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        type = try container.decode(String.self, forKey: .type)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        question = try container.decode(String.self, forKey: .question)
        correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        incorrectAnswers = try container.decode([String].self, forKey: .incorrectAnswers)
        
        // Shuffle and store answers once during initialization
        _shuffledAnswers = (incorrectAnswers + [correctAnswer]).shuffled()
    }
    
    // Custom encoder to handle the private property
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(type, forKey: .type)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(question, forKey: .question)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encode(incorrectAnswers, forKey: .incorrectAnswers)
    }
    
    // Return pre-shuffled answers
    var allAnswers: [String] {
        return _shuffledAnswers ?? (incorrectAnswers + [correctAnswer])
    }
    
    // Decoded question text (handles HTML entities)
    var decodedQuestion: String {
        question.htmlDecoded
    }
    
    // Decoded answers
    var decodedCorrectAnswer: String {
        correctAnswer.htmlDecoded
    }
    
    var decodedAllAnswers: [String] {
        allAnswers.map { $0.htmlDecoded }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TriviaQuestion, rhs: TriviaQuestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Question Categories
enum TriviaCategory: String, CaseIterable, Identifiable {
    case any = "Any Category"
    case generalKnowledge = "General Knowledge"
    case books = "Books"
    case film = "Film"
    case music = "Music"
    case musicalsTheatres = "Musicals & Theatres"
    case television = "Television"
    case videoGames = "Video Games"
    case boardGames = "Board Games"
    case scienceNature = "Science & Nature"
    case computers = "Computers"
    case mathematics = "Mathematics"
    case mythology = "Mythology"
    case sports = "Sports"
    case geography = "Geography"
    case history = "History"
    case politics = "Politics"
    case art = "Art"
    case celebrities = "Celebrities"
    case animals = "Animals"
    case vehicles = "Vehicles"
    case comics = "Comics"
    case gadgets = "Gadgets"
    case anime = "Anime & Manga"
    case cartoon = "Cartoon & Animations"
    
    var id: String { rawValue }
    
    var apiValue: String? {
        switch self {
        case .any: return nil
        case .generalKnowledge: return "9"
        case .books: return "10"
        case .film: return "11"
        case .music: return "12"
        case .musicalsTheatres: return "13"
        case .television: return "14"
        case .videoGames: return "15"
        case .boardGames: return "16"
        case .scienceNature: return "17"
        case .computers: return "18"
        case .mathematics: return "19"
        case .mythology: return "20"
        case .sports: return "21"
        case .geography: return "22"
        case .history: return "23"
        case .politics: return "24"
        case .art: return "25"
        case .celebrities: return "26"
        case .animals: return "27"
        case .vehicles: return "28"
        case .comics: return "29"
        case .gadgets: return "30"
        case .anime: return "31"
        case .cartoon: return "32"
        }
    }
}

// MARK: - Difficulty Levels
enum TriviaDifficulty: String, CaseIterable, Identifiable {
    case any = "Any Difficulty"
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { rawValue }
    
    var apiValue: String? {
        switch self {
        case .any: return nil
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }
}

// MARK: - Question Types
enum TriviaQuestionType: String, CaseIterable, Identifiable {
    case any = "Any Type"
    case multipleChoice = "Multiple Choice"
    case trueFalse = "True / False"
    
    var id: String { rawValue }
    
    var apiValue: String? {
        switch self {
        case .any: return nil
        case .multipleChoice: return "multiple"
        case .trueFalse: return "boolean"
        }
    }
}

// MARK: - HTML Decoding Extension
extension String {
    var htmlDecoded: String {
        var result = self
        
        // Common HTML entities
        let entities = [
            ("&quot;", "\""),
            ("&amp;", "&"),
            ("&apos;", "'"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&#039;", "'"),
            ("&rsquo;", "'"),
            ("&lsquo;", "'"),
            ("&rdquo;", "\""),
            ("&ldquo;", "\""),
            ("&nbsp;", " "),
            ("&eacute;", "é"),
            ("&ntilde;", "ñ"),
            ("&ouml;", "ö"),
            ("&uuml;", "ü"),
            ("&auml;", "ä")
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result
    }
}

// MARK: - User Answer Tracking
struct UserAnswer: Identifiable {
    let id = UUID()
    let question: TriviaQuestion
    var selectedAnswer: String?
    
    var isCorrect: Bool? {
        guard let selected = selectedAnswer else { return nil }
        return selected == question.correctAnswer
    }
}
