# HideAIChat

**A transparent macOS overlay for chatting with Notion AI.**

HideAIChat turns your desktop into a stealth AI terminal. Hit `⌘⌥N` — a barely-visible overlay appears over any app. Type your question, get an AI response, then vanish back to work. Powered by your Notion AI subscription via [notion2api](https://github.com/p0n1/epub_to_txt/tree/main/notion2api).

## Demo

<p align="center">
  <img src="docs/screenshot.png" alt="HideAIChat screenshot" width="600"/>
</p>

## Features

- **Stealth mode** — nearly invisible when idle (`opacity: 0.025`), smoothly appears on hotkey
- **Notion AI integration** — uses your Notion AI subscription (no separate API key needed)
- **Streaming responses** — typewriter-style output with markdown rendering
- **Chat history** — auto-saves conversations, browse and restore via the ⋮ menu
- **Multi-model support** — switch between available Notion AI models
- **EN / RU** — English and Russian interface languages

## Requirements

- macOS 15 (Sequoia) or later (Apple Silicon)
- Active [Notion AI](https://www.notion.so/product/ai) subscription
- Notion `token_v2` cookie (exported from browser)

## Setup

### 1. Install notion2api

```bash
git clone https://github.com/p0n1/epub_to_txt.git ~/notion2api
cd ~/notion2api/notion2api

# Install dependencies
npm install

# Create config
cp config.example.json config.json
```

### 2. Configure Notion auth

1. Open [Notion](https://www.notion.so) in your browser
2. Open Developer Tools (`⌘⌥I`) → Application → Cookies → `www.notion.so`
3. Copy the value of `token_v2`
4. Paste it into `~/notion2api/notion2api/config.json`:

```json
{
  "token_v2": "your_token_v2_here",
  "port": 3123
}
```

### 3. Start notion2api

```bash
cd ~/notion2api/notion2api && npm start
```

The server must be running on `http://localhost:3123` before launching HideAIChat.

### 4. Run HideAIChat

```bash
# From source
cd ~/HideAIChat
swift run

# Or open the DMG
open HideAIChat.dmg
```

## Usage

| Action | Shortcut |
|--------|----------|
| Toggle overlay | `⌘⌥N` |
| Send message | `Enter` |
| Close | `⌘⌥N` or click ✕ |
| History | Click ⋮ in header |

The overlay is click-through when idle. Press `⌘⌥N` to activate.

## Build from source

```bash
git clone https://github.com/ArtemPotapov52/HideAIChat.git
cd HideAIChat
swift build -c release
cp .build/arm64-apple-macosx/release/TransparentNotion .build/TransparentNotion.app/Contents/MacOS/
open .build/TransparentNotion.app
```

## Architecture

```
HideAIChat/
├── Sources/
│   └── TransparentNotion/
│       ├── App.swift         — App entry, overlay panel, hotkey
│       ├── Views.swift       — Chat UI, messages, markdown, input
│       ├── NotionAPI.swift   — Streaming API client for notion2api
│       ├── History.swift     — Chat history persistence
│       ├── Info.plist        — LSUIElement = true
│       └── Resources/
│           └── AppIcon.icns
├── docs/
│   └── index.html            — Landing page (GitHub Pages)
├── Package.swift
└── README.md
```

## Tech stack

- **Swift 6.3** + **SwiftUI** + **AppKit** (NSPanel, NSVisualEffectView)
- **notion2api** — reverse-engineered Notion AI API wrapper
- **SwiftPM** — build system
- **Markdown** — AttributedString rendering with heading support

## Credits

- [notion2api](https://github.com/p0n1/epub_to_txt/tree/main/notion2api) by p0n1
- Notion AI by Notion Labs

## License

MIT
