# linkedin-desktop-widget

A native macOS desktop widget that shows your LinkedIn feed at a glance. Built with SwiftUI, powered by [`linkedin-cli`](https://github.com/sderosiaux/linkedin-cli).

Floats on your desktop like a weather widget. No Dock icon, no menu bar clutter. Just a translucent panel with your latest posts sorted by date.

![screenshot](screenshot.png)

## Features

- **Sorted by date** -- most recent posts first, always
- **Fresh indicator** -- green dot on posts less than 4 hours old
- **Semantic search** -- uses Ollama embeddings for conceptual matching, with SQL fallback if Ollama is not running
- **Hover actions** on each post:
  - **Read** -- mark as read (hides from feed, stored locally)
  - **Not for me** -- hides + tells the CLI to filter similar content from future timelines (embedding-based)
  - **More like this** -- finds semantically similar posts
- **Click to open** -- click any post to open it in your browser
- **Auto-refresh** -- updates every 5 minutes from local DB (no API calls)
- **Resizable** -- drag the bottom-right corner to resize both axes
- **Remembers position and size** across launches
- **Translucent HUD** -- native macOS vibrancy material, rounded corners
- **Desktop-level window** -- sits behind normal windows, visible on all Spaces
- **Menu** -- ellipsis button in header for refresh, unhide all, quit
- **SwiftLint enforced** -- strict linting with opt-in rules

## Prerequisites

- macOS 14+
- Swift 5.9+
- [`linkedin-cli`](https://github.com/sderosiaux/linkedin-cli) installed via bun
- A populated local database (`linkedin sync` run at least once)
- [Ollama](https://ollama.com) with `nomic-embed-text` (optional, for semantic search and "Not for me" filtering)

## Install

```bash
git clone https://github.com/sderosiaux/linkedin-desktop-widget.git
cd linkedin-desktop-widget
swift build -c release
cp .build/release/LinkedInWidget ~/.local/bin/
```

## Usage

```bash
LinkedInWidget
```

The widget appears in the top-right corner of your screen. Drag to reposition. Drag the bottom-right corner to resize.

There is no Dock icon. Use the ellipsis menu to quit, or `pkill LinkedInWidget`.

### Search

Type in the search bar to find posts. If Ollama is running with embeddings generated (`linkedin embed`), the widget uses semantic search to find conceptually related posts and shows a similarity percentage. Otherwise, it falls back to SQL text matching.

### Post actions

Hover any post to see action buttons:

| Button | What it does | Where it's stored |
|---|---|---|
| **Read** | Hides the post from feed | Widget local file (`~/.local/share/linkedin-widget/hidden.json`) |
| **Not for me** | Hides + filters similar content from future timelines | Widget local file + CLI SQLite (`disliked_post` table) |
| **More like this** | Semantic search for similar posts | Fills the search bar |

### Keeping data fresh

The widget reads from `linkedin-cli`'s local SQLite database. It never calls the LinkedIn API directly. To keep your data fresh:

```bash
# Manual sync
linkedin sync

# Or via cron (every 30 minutes)
*/30 * * * * /Users/you/.bun/bin/linkedin sync
```

### Launch at login

```bash
cat > ~/Library/LaunchAgents/com.linkedin-widget.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.linkedin-widget</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/LinkedInWidget</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.linkedin-widget.plist
```

## Project structure

```
Package.swift              # SPM manifest, macOS 14+
.swiftlint.yml             # Strict lint rules
Sources/
  main.swift               # App entry point
  AppDelegate.swift        # Window setup, edit menu for Cmd shortcuts
  Models.swift             # Post model, date sorting, recency detection
  LinkedInService.swift    # Runs linkedin-cli, semantic + SQL search, dislike
  WidgetStore.swift        # Observable state, hide/dislike, debounced search
  WidgetView.swift         # Main layout (header, search, post list, menu)
  PostRow.swift            # Post row with hover action buttons
  ResizableWindow.swift    # NSWindow subclass with corner resize
  ResizeHandle.swift       # Corner resize grip indicator
```

## License

MIT
