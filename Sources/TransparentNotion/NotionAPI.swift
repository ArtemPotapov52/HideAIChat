import Foundation

actor NotionAPI {
    static let shared = NotionAPI()
    private let base = "http://localhost:3123"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    struct ChatChunk: Decodable {
        let choices: [Choice]?
    }
    struct Choice: Decodable {
        let delta: Delta?
        let message: MessageContent?
    }
    struct Delta: Decodable {
        let content: String?
    }
    struct MessageContent: Decodable {
        let content: String?
    }

    func streamChat(model: String, messages: [(String, String)], onChunk: @escaping @Sendable (String) -> Void) async throws {
        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.0, "content": $0.1] },
            "stream": true
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: URL(string: "\(base)/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonData

        let (bytes, response) = try await session.bytes(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if data == "[DONE]" { break }
                guard let jsonData = data.data(using: .utf8),
                      let chunk = try? JSONDecoder().decode(ChatChunk.self, from: jsonData) else { continue }
                if let content = chunk.choices?.first?.delta?.content {
                    onChunk(content)
                } else if let content = chunk.choices?.first?.message?.content {
                    onChunk(content)
                }
            }
        }
    }

    func simpleChat(model: String, messages: [(String, String)]) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.0, "content": $0.1] },
            "stream": false
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: URL(string: "\(base)/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonData

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let result = try JSONDecoder().decode(ChatChunk.self, from: data)
        return result.choices?.first?.message?.content ?? ""
    }
}
