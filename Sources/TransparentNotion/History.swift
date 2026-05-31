import Foundation

struct ChatHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let model: String
    let createdAt: Date
    var messages: [HistoryMessage]

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: createdAt)
    }
}

struct HistoryMessage: Codable, Equatable {
    let role: String
    let content: String
}

@MainActor final class ChatHistoryManager {
    static let shared = ChatHistoryManager()
    private let url: URL
    private var entries: [ChatHistoryEntry] = []

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        url = home.appendingPathComponent("TransparentNotion/chat_history.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ChatHistoryEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url)
    }

    var allEntries: [ChatHistoryEntry] { entries }

    func addEntry(_ entry: ChatHistoryEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func updateEntry(_ id: UUID, messages: [HistoryMessage]) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].messages = messages
        save()
    }
}
