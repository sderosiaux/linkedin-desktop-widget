# linkedin-desktop-widget

A native macOS desktop widget that shows your LinkedIn feed at a glance. Built with SwiftUI, powered by [`linkedin-cli`](https://github.com/sderosiaux/linkedin-cli).

Floats on your desktop like a weather widget. No Dock icon, no menu bar clutter. Just a translucent panel with your most relevant posts, ranked by engagement and recency.

## Features

- **Fusion ranking** -- posts scored by `likes + comments*2 + recency_boost` (linear decay over 1 week)
- **Search filter** -- filter by author name, company, or keyword across all post content
- **Link indicator** -- posts containing URLs show a link icon
- **Click to open** -- click any post to open it in your browser
- **Auto-refresh** -- updates every 5 minutes from local DB (no API calls)
- **Resizable** -- drag the bottom handle to resize vertically
- **Remembers position and size** across launches
- **Translucent HUD** -- native macOS vibrancy material, rounded corners
- **Desktop-level window** -- sits behind normal windows, visible on all Spaces
- **Right-click** to manually refresh or quit

## Prerequisites

- macOS 14+
- Swift 5.9+
- [`linkedin-cli`](https://github.com/sderosiaux/linkedin-cli) installed via bun
- A populated local database (`linkedin sync` run at least once)

## Install

```bash
git clone https://github.com/sderosiaux/linkedin-desktop-widget.git
cd linkedin-desktop-widget
swift build -c release
```

The binary is at `.build/release/LinkedInWidget`.

## Usage

```bash
# Run the widget
.build/release/LinkedInWidget

# Or from debug build
swift run
```

The widget appears in the top-right corner of your screen. Drag to reposition. Drag the bottom handle to resize.

There is no Dock icon. Right-click the widget to quit, or use `pkill LinkedInWidget`.

### Keeping data fresh

The widget reads from `linkedin-cli`'s local SQLite database. It never calls the LinkedIn API directly. To keep your data fresh, run `linkedin sync` periodically:

```bash
# Manual sync
linkedin sync

# Or via cron (every 30 minutes)
crontab -e
*/30 * * * * /Users/you/.bun/bin/linkedin sync
```

### Launch at login

Add the built binary to **System Settings > General > Login Items**, or create a Launch Agent:

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
Sources/
  main.swift               # App entry point
  AppDelegate.swift        # Window setup (borderless, translucent, desktop-level)
  Models.swift             # Post model, ranking, search matching
  LinkedInService.swift    # Runs linkedin-cli, parses JSON, caches results
  WidgetStore.swift        # Observable state (posts, search query, refresh)
  WidgetView.swift         # Main widget layout (header, search, post list)
  PostRow.swift            # Individual post row
  ResizableWindow.swift    # NSWindow subclass with bottom-edge resize
  ResizeHandle.swift       # Visible drag handle view
```

## License

MIT
