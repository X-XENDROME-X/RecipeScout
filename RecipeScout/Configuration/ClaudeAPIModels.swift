//
//  ClaudeAPIModels.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Request and response models for Claude API communication

import Foundation

// MARK: - Request Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
    let temperature: Double?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
        case temperature
    }
    
    init(
        model: String = "claude-sonnet-4-5-20250929",
        maxTokens: Int = 4096,
        messages: [ClaudeMessage],
        system: String? = nil,
        temperature: Double = 0.7
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
        self.temperature = temperature
    }
}

struct ClaudeMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    
    enum MessageRole: String, Codable {
        case user
        case assistant
    }
    
    enum CodingKeys: String, CodingKey {
        case role
        case content
        // Note: 'id' is intentionally excluded from encoding/decoding
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
    
    // Custom decoding to generate UUID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.role = try container.decode(MessageRole.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
    }
    
    // Custom encoding to exclude id
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

// MARK: - Response Models

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let usage: UsageInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case role
        case content
        case model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

struct UsageInfo: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
    
    var totalTokens: Int {
        return inputTokens + outputTokens
    }
}

// MARK: - Error Response

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ErrorDetail
    
    struct ErrorDetail: Codable {
        let type: String
        let message: String
    }
}
