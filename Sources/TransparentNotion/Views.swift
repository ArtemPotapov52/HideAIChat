import Cocoa
import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: String
    var content: String
    var isStreaming = false
}

struct ContentView: View {
    let controller: OverlayController
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var isLoading = false
    @State private var showHistory = false
    @State private var currentEntryId: UUID?

    private var lang: Lang { Lang(controller.language) }
    private var contentOpacity: Double { controller.isActive ? 0.92 : 0.025 }
    private var bgOpacity: Double { controller.isActive ? 0.5 : 0.005 }

    var body: some View {
        VStack(spacing: 4) {
            header
            messagesList
            inputBar
        }
        .padding(.horizontal, 4)
        .opacity(contentOpacity)
        .animation(.easeOut(duration: 0.2), value: contentOpacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffect(material: .sidebar, blending: .behindWindow)
                .opacity(bgOpacity)
                .animation(.easeOut(duration: 0.2), value: bgOpacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(controller.isActive ? 0.06 : 0.015), lineWidth: 1)
                .animation(.easeOut(duration: 0.2), value: controller.isActive)
        )
        .shadow(color: .black.opacity(controller.isActive ? 0.2 : 0.01),
                radius: controller.isActive ? 20 : 2)
        .animation(.easeOut(duration: 0.2), value: controller.isActive)
        .overlay(historyOverlay)
    }

    @ViewBuilder
    private var historyOverlay: some View {
        if showHistory {
            historyPanel
        }
    }

    private var historyPanel: some View {
        let entries = ChatHistoryManager.shared.allEntries
        return VStack(spacing: 0) {
            HStack {
                Text(lang.history)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Button { showHistory = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Divider().opacity(0.1)

            if entries.isEmpty {
                VStack {
                    Text(lang.noHistory)
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.15))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(entries) { entry in
                            Button {
                                loadEntry(entry)
                                showHistory = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.title)
                                            .font(.system(size: 10.5))
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(1)
                                        Text(entry.formattedDate)
                                            .font(.system(size: 8.5))
                                            .foregroundColor(.white.opacity(0.2))
                                    }
                                    Spacer()
                                    Button { ChatHistoryManager.shared.deleteEntry(entry.id) } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 7))
                                            .foregroundColor(.white.opacity(0.15))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 240, height: entries.isEmpty ? 100 : 300)
        .background(
            VisualEffect(material: .popover, blending: .behindWindow).opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 16)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(duration: 0.25), value: showHistory)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button { showHistory.toggle() } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.2))
                    .rotationEffect(.degrees(90))
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(controller.availableModels, id: \.id) { m in
                    Button {
                        controller.selectedModel = m.id
                    } label: {
                        HStack {
                            Text(m.name).font(.system(size: 11))
                            if m.id == controller.selectedModel {
                                Image(systemName: "checkmark").font(.system(size: 8))
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                    Text(controller.selectedModelName)
                        .font(.system(size: 9.5, weight: .medium))
                    Image(systemName: "chevron-down")
                        .font(.system(size: 5.5, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.2))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()

            Button { controller.toggle() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 6) {
                    if messages.isEmpty { emptyState }
                    ForEach(messages) { msg in
                        MessageBubble(message: msg, lang: lang).id(msg.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: messages.count) { _, _ in scrollToLast(proxy) }
            .onChange(of: messages.last?.content.count) { _, _ in scrollToLast(proxy) }
        }
    }

    private func scrollToLast(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(last.id, anchor: .bottom) }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text(lang.askAnything)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.15))
            Text("⌘⌥N · \(lang.toHide)")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.08))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField(lang.inputPlaceholder, text: $input)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .onSubmit(of: .text) { send() }

            Button { send() } label: {
                ZStack {
                    if isLoading {
                        ProgressView().scaleEffect(0.5).frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        input = ""
        isLoading = true
        messages.append(Message(role: "user", content: text))
        messages.append(Message(role: "assistant", content: "", isStreaming: true))
        let aiId = messages.last!.id
        saveCurrentConversation()

        let history = messages.filter { $0.id != aiId }.map { ($0.role, $0.content) }
        Task {
            do {
                try await NotionAPI.shared.streamChat(
                    model: controller.selectedModel,
                    messages: history,
                    onChunk: { chunk in
                        Task { @MainActor in
                            if let i = messages.firstIndex(where: { $0.id == aiId }) {
                                messages[i].content += chunk
                            }
                        }
                    }
                )
            } catch {
                Task { @MainActor in
                    if let i = messages.firstIndex(where: { $0.id == aiId }) {
                        messages[i].content = "⚠️ \(error.localizedDescription)"
                        messages[i].isStreaming = false
                    }
                }
            }
            Task { @MainActor in
                if let i = messages.firstIndex(where: { $0.id == aiId }) {
                    messages[i].isStreaming = false
                }
                isLoading = false
                saveCurrentConversation()
            }
        }
    }

    private func saveCurrentConversation() {
        guard !messages.isEmpty else { return }
        let hms = messages.map { HistoryMessage(role: $0.role, content: $0.content) }
        let title = String(messages.first?.content.prefix(60).trimmingCharacters(in: .whitespaces) ?? "Chat")
        if let eid = currentEntryId {
            ChatHistoryManager.shared.updateEntry(eid, messages: hms)
        } else {
            let entry = ChatHistoryEntry(
                id: UUID(), title: title, model: controller.selectedModel,
                createdAt: Date(), messages: hms
            )
            currentEntryId = entry.id
            ChatHistoryManager.shared.addEntry(entry)
        }
    }

    private func loadEntry(_ entry: ChatHistoryEntry) {
        currentEntryId = entry.id
        messages = entry.messages.map { Message(role: $0.role, content: $0.content) }
        controller.selectedModel = entry.model
    }
}

struct MessageBubble: View {
    let message: Message
    let lang: Lang

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if message.role == "user" { Spacer(minLength: 32) }
            if message.role == "assistant" {
                Image(systemName: "brain")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.12))
                    .padding(.top, 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                StreamingText(content: message.content, isStreaming: message.isStreaming)
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                if message.isStreaming {
                    HStack(spacing: 2) {
                        DotIndicator(delay: 0)
                        DotIndicator(delay: 0.2)
                        DotIndicator(delay: 0.4)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(message.role == "user" ? Color.white.opacity(0.05) : Color.white.opacity(0.015))
            )
            if message.role == "assistant" { Spacer(minLength: 32) }
        }
    }
}

private func normalizeMarkdown(_ text: String) -> String {
    var s = text
    s.replace( #/\[\^\(\(([^)]+)\)\)\]/# ) { match in
        "[source](\(match.1))"
    }
    s.replace( #/\[\^\(([^)]+)\)\]/# ) { match in
        "[source](\(match.1))"
    }
    s.replace( #/\[ref\]\(([^)]+)\)/# ) { match in
        "[ref](\(match.1))"
    }
    return s
}

private func renderMarkdown(_ text: String, full: Bool) -> AttributedString {
    let mode: AttributedString.MarkdownParsingOptions.InterpretedSyntax = full ? .full : .inlineOnlyPreservingWhitespace
    let processed: String
    if full {
        processed = normalizeMarkdown(text)
    } else {
        processed = normalizeMarkdown(text)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.hasPrefix("### ") ? "**" + $0.dropFirst(4) + "**" : $0 }
            .joined(separator: "\n")
    }
    return (try? AttributedString(markdown: processed, options: .init(interpretedSyntax: mode)))
        ?? AttributedString(text)
}

private struct TableBlock: Identifiable {
    let id = UUID()
    let headers: [String]
    let rows: [[String]]
}

private enum ContentBlock: Identifiable {
    var id: UUID { UUID() }
    case text(String)
    case table(TableBlock)
}

private func parseBlocks(_ text: String) -> [ContentBlock] {
    var blocks: [ContentBlock] = []
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var i = 0
    while i < lines.count {
        if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
            var tableLines: [String] = []
            while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                tableLines.append(lines[i])
                i += 1
            }
            if let table = parseTable(tableLines) {
                blocks.append(.table(table))
            } else {
                blocks.append(.text(tableLines.joined(separator: "\n")))
            }
        } else {
            var textLines: [String] = []
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                textLines.append(lines[i])
                i += 1
            }
            blocks.append(.text(textLines.joined(separator: "\n")))
        }
    }
    return blocks
}

private func parseTable(_ lines: [String]) -> TableBlock? {
    guard lines.count >= 2 else { return nil }
    let sep = lines[1].trimmingCharacters(in: .whitespaces)
    let hasSep = sep.contains("---") || sep.contains("===")
    let dataStart = hasSep ? 2 : 1
    let headers = lines[0]
        .trimmingCharacters(in: .whitespaces)
        .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        .split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
    guard !headers.isEmpty else { return nil }
    var rows: [[String]] = []
    for line in lines.dropFirst(dataStart) {
        let cells = line
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            .split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
        if !cells.isEmpty {
            rows.append(cells)
        }
    }
    return rows.isEmpty ? nil : TableBlock(headers: headers, rows: rows)
}

struct StreamingText: View {
    let content: String
    let isStreaming: Bool
    @State private var displayed = ""
    @State private var streamTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isStreaming {
                Text(renderMarkdown(displayed, full: false))
            } else {
                renderedBlocks
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
        .onChange(of: content, initial: true) { _, new in
            streamTask?.cancel()
            if isStreaming {
                streamTask = Task {
                    let start = displayed.count
                    let rest = String(new.dropFirst(start))
                    for ch in rest {
                        try? await Task.sleep(nanoseconds: 10_000_000)
                        if Task.isCancelled { return }
                        displayed.append(ch)
                    }
                }
            } else {
                displayed = new
            }
        }
    }

    @ViewBuilder
    private var renderedBlocks: some View {
        let blocks = parseBlocks(displayed)
        VStack(alignment: .leading, spacing: 6) {
            ForEach(blocks.indices, id: \.self) { i in
                switch blocks[i] {
                case .text(let md):
                    Text(renderMarkdown(md, full: true))
                case .table(let t):
                    TableView(block: t)
                }
            }
        }
    }
}

private struct TableView: View {
    let block: TableBlock

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            GridRow {
                ForEach(block.headers.indices, id: \.self) { i in
                    Text(block.headers[i])
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Divider().gridCellUnsizedAxes(.horizontal).opacity(0.15)
            ForEach(block.rows.indices, id: \.self) { r in
                GridRow {
                    ForEach(block.rows[r].indices, id: \.self) { c in
                        Text(block.rows[r][c])
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct DotIndicator: View {
    let delay: Double
    @State private var show = false
    var body: some View {
        Circle().fill(Color.white.opacity(0.2)).frame(width: 3, height: 3)
            .opacity(show ? 1 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(delay)) { show = true }
            }
    }
}

struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blending: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .followsWindowActiveState
        v.wantsLayer = true
        v.layer?.cornerRadius = 16
        v.layer?.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner,
                                  .layerMaxXMinYCorner, .layerMinXMinYCorner]
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}

struct Lang {
    let code: String
    init(_ code: String) { self.code = code }
    var tapToAsk: String { code == "ru" ? "Нажмите, чтобы спросить" : "Tap to ask" }
    var askAnything: String { code == "ru" ? "Спросите что угодно" : "Ask anything" }
    var inputPlaceholder: String { code == "ru" ? "Задайте вопрос..." : "Ask a question..." }
    var toHide: String { code == "ru" ? "скрыть" : "hide" }
    var history: String { code == "ru" ? "История" : "History" }
    var noHistory: String { code == "ru" ? "История пуста" : "No history yet" }
}
