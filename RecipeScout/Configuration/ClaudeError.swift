//
//  ClaudeError.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Error types for Claude API interactions with detailed error handling

import Foundation

enum ClaudeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded(retryAfter: Int?)
    case invalidAPIKey
    case contextTooLarge(tokenCount: Int, maxTokens: Int)
    case serverError(String)
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
            
        case .invalidResponse:
            return "Invalid response from Claude API"
            
        case .httpError(let statusCode, let message):
            if let msg = message {
                return "HTTP Error \(statusCode): \(msg)"
            }
            return "HTTP Error \(statusCode)"
            
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
            
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
            
        case .rateLimitExceeded(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Retry after \(retry) seconds."
            }
            return "Rate limit exceeded. Please try again later."
            
        case .invalidAPIKey:
            return "Invalid or missing Claude API key"
            
        case .contextTooLarge(let tokenCount, let maxTokens):
            return "Context too large: \(tokenCount) tokens (max: \(maxTokens))"
            
        case .serverError(let message):
            return "Server error: \(message)"
            
        case .missingAPIKey:
            return "Claude API key not configured"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey, .missingAPIKey:
            return "Please add your Claude API key to the .env file"
            
        case .rateLimitExceeded:
            return "Wait a moment before sending another message"
            
        case .contextTooLarge:
            return "Try shortening your message or clearing conversation history"
            
        case .networkError:
            return "Check your internet connection and try again"
            
        default:
            return "Please try again later"
        }
    }
}
