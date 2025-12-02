# iClippy - macOS Clipboard History

A lightweight macOS clipboard history manager that records text clipboard items into a local SQLite database and provides quick access via a global hotkey.

## Features

- 📋 **Text-Only Recording**: Automatically captures text clipboard items (ignores images, files, etc.)
- 🔍 **Searchable History**: Search through your clipboard history with a simple search interface
- ⚡ **Global Hotkey**: Press `Option+V` (⌥V) anywhere to open the clipboard history window
- 🚫 **No Duplicates**: Each unique text is stored only once
- 💾 **Portable Database**: SQLite database stored in a standard location for easy backup and migration
- 🔒 **Privacy-First**: All data stays local, no analytics or telemetry

## Installation & Building

### Requirements
- macOS 13.0 or later
- Xcode 14.0+ with Swift 5.9+

### Build from Source

#### Option 1: Using Xcode (Recommended)

```bash
# Clone the repository
git clone https://github.com/pedromrcosta/iClippyV2.git
cd iClippyV2

# Open the Xcode project
open iClippy.xcodeproj
```

In Xcode:
1. Select the "iClippy" scheme
2. Press `⌘B` to build or `⌘R` to run
3. The app will appear in the menu bar when running

#### Option 2: Using Swift Package Manager (Command Line)

```bash
# Clone the repository
git clone https://github.com/pedromrcosta/iClippyV2.git
cd iClippyV2

# Build the app
swift build -c release

# Run the app
.build/release/iClippy
```

## Usage

1. **Start the app**: Launch iClippy - it runs in the background monitoring your clipboard
2. **Copy text**: Copy any text as usual (⌘C) - iClippy automatically records it
3. **View history**: Press `Option+V` (⌥V) to open the history window
4. **Search**: Type in the search field to filter entries
5. **Restore**: Click any entry to copy it back to your clipboard

## Database Location

iClippy stores clipboard history in:
```
~/Library/Application Support/iClippy/iclippy.sqlite3
```

You can backup or copy this file between machines to migrate your clipboard history.

## Testing

Run the test suite:

```bash
swift test
```

The tests cover:
- Adding entries to the database
- Duplicate prevention
- Whitespace trimming
- Search functionality
- Limit and ordering

## Architecture

- **DBManager**: SQLite database operations (add, fetch, search)
- **ClipboardMonitor**: Polls NSPasteboard for text changes
- **HotKeyManager**: Registers global Option+V hotkey using Carbon API
- **AppDelegate**: Wires components and manages the history window
- **HistoryView**: SwiftUI interface for displaying and searching history

## Database Schema

```sql
CREATE TABLE entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    text TEXT UNIQUE NOT NULL,
    created_at INTEGER NOT NULL
);
```

## Privacy

- All clipboard data is stored locally on your machine
- No network access or external communication
- No analytics or telemetry
- Database is only readable by your user account

## License

See LICENSE file for details.
