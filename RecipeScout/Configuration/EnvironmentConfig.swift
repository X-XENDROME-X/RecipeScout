import Foundation

final class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    private let values: [String: String]

    private init() {
        if let url = Bundle.main.url(forResource: ".env", withExtension: nil),
           let data = try? String(contentsOf: url, encoding: .utf8) {
            values = EnvironmentConfig.parse(data)
        } else {
            values = [:]
        }
    }

    var apiBaseURL: String {
        guard let value = values["API_BASE_URL"], !value.isEmpty else {
            fatalError("API_BASE_URL missing. Copy Configuration/.env.template to Configuration/.env and add it to the RecipeScout target.")
        }
        return value
    }
    
    var claudeAPIKey: String? {
        guard let value = values["CLAUDE_API_KEY"], !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func parse(_ input: String) -> [String: String] {
        var result: [String: String] = [:]
        input.components(separatedBy: .newlines).forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { 
                return 
            }
            let parts = trimmed.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                let key = parts[0]
                let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                result[key] = value
            }
        }
        return result
    }
}
