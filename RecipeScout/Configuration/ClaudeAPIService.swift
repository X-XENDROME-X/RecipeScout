//
//  ClaudeAPIService.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Secure service layer for Claude API communication with rate limiting, retry logic, and comprehensive error handling

import Foundation

@MainActor
final class ClaudeAPIService {
    
    static let shared = ClaudeAPIService()
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let session: URLSession
    
    // Rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.5 // 500ms between requests
    
    // Token usage tracking
    private(set) var totalTokensUsed: Int = 0
    private(set) var requestCount: Int = 0
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        
        // Security headers
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Send a message to Claude and get a response
    func sendMessage(
        messages: [ClaudeMessage],
        systemPrompt: String? = nil,
        temperature: Double = 0.7
    ) async throws -> ClaudeResponse {
        
        // Rate limiting
        try await enforceRateLimit()
        
        // Get API key securely
        let apiKey = try getAPIKey()
        
        // Create request
        let claudeRequest = ClaudeRequest(
            messages: messages,
            system: systemPrompt,
            temperature: temperature
        )
        
        // Prepare URL request
        guard let url = URL(string: baseURL) else {
            throw ClaudeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        // Encode request body
        do {
            request.httpBody = try JSONEncoder().encode(claudeRequest)
        } catch {
            throw ClaudeError.decodingError(error)
        }
        
        // Make request with retry logic
        let response = try await performRequestWithRetry(request)
        
        // Update tracking
        requestCount += 1
        totalTokensUsed += response.usage.totalTokens
        
        return response
    }
    
    /// Check if API key is configured
    func isAPIKeyConfigured() -> Bool {
        do {
            _ = try getAPIKey()
            return true
        } catch {
            return false
        }
    }
    
    /// Reset token usage statistics
    func resetStatistics() {
        totalTokensUsed = 0
        requestCount = 0
    }
    
    // MARK: - Private Methods
    
    private func getAPIKey() throws -> String {
        guard let key = EnvironmentConfig.shared.claudeAPIKey, !key.isEmpty else {
            throw ClaudeError.missingAPIKey
        }
        return key
    }
    
    private func enforceRateLimit() async throws {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRequestInterval {
                let waitTime = minimumRequestInterval - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    private func performRequestWithRetry(_ request: URLRequest, retryCount: Int = 0) async throws -> ClaudeResponse {
        let maxRetries = 3
        
        do {
            let (data, urlResponse) = try await session.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw ClaudeError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                return try decodeResponse(data)
                
            case 429:
                // Rate limit
                let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap(Int.init)
                
                if retryCount < maxRetries, let retry = retryAfter {
                    try await Task.sleep(nanoseconds: UInt64(retry * 1_000_000_000))
                    return try await performRequestWithRetry(request, retryCount: retryCount + 1)
                }
                
                throw ClaudeError.rateLimitExceeded(retryAfter: retryAfter)
                
            case 401:
                throw ClaudeError.invalidAPIKey
                
            case 400...499:
                // Client error
                let errorMessage = try? decodeErrorResponse(data)
                throw ClaudeError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                
            case 500...599:
                // Server error - retry with exponential backoff
                if retryCount < maxRetries {
                    let backoffTime = pow(2.0, Double(retryCount))
                    try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))
                    return try await performRequestWithRetry(request, retryCount: retryCount + 1)
                }
                
                let errorMessage = try? decodeErrorResponse(data)
                throw ClaudeError.serverError(errorMessage ?? "Unknown server error")
                
            default:
                throw ClaudeError.httpError(statusCode: httpResponse.statusCode, message: nil)
            }
            
        } catch let error as ClaudeError {
            throw error
        } catch {
            throw ClaudeError.networkError(error)
        }
    }
    
    private func decodeResponse(_ data: Data) throws -> ClaudeResponse {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ClaudeResponse.self, from: data)
        } catch {
            throw ClaudeError.decodingError(error)
        }
    }
    
    private func decodeErrorResponse(_ data: Data) throws -> String {
        let decoder = JSONDecoder()
        do {
            let errorResponse = try decoder.decode(ClaudeErrorResponse.self, from: data)
            return errorResponse.error.message
        } catch {
            return String(data: data, encoding: .utf8) ?? "Unknown error"
        }
    }
}
