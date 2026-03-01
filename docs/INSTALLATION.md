# Installation Guide

This guide covers all ways to install Prompteria on macOS.

## Requirements

- **macOS 14.0** (Sonoma) or later
- Apple Silicon or Intel Mac

---

## Option 1: Download Pre-built Release (Recommended)

1. Go to the [Releases](https://github.com/fortin/prompteria/releases) page
2. Download the latest `Prompteria-*.dmg` file
3. Open the DMG and drag Prompteria to your Applications folder
4. **First launch (unsigned builds only):** Right-click the app → **Open**, then confirm in the dialog

> **Note:** Official releases are signed and notarized—no right-click needed. Builds from forks or CI may be unsigned; use Right-click → Open for those.

---

## Option 2: Build from Source

For developers or users who prefer to build from source:

### Prerequisites

- [Xcode 16+](https://developer.apple.com/xcode/) (from the Mac App Store)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Quick Build

```bash
# Clone the repository
git clone https://github.com/fortin/prompteria.git
cd prompteria

# Generate Xcode project
xcodegen generate

# Open in Xcode and build (⌘R)
open Prompteria.xcodeproj
```

### Build a Release DMG

```bash
./scripts/build-release.sh 1.0.0
```

The DMG will be created at `build/Prompteria-1.0.0.dmg`.

For a nicer DMG with an Applications shortcut, install [create-dmg](https://github.com/create-dmg/create-dmg):

```bash
brew install create-dmg
./scripts/build-release.sh 1.0.0
```

---

## Data Location

After installation, Prompteria stores your prompt library at:

```
~/Library/Application Support/Prompteria/prompts.db
```

Backup and restore uses this database. See [Backup & Restore](BACKUP.md) for details.

---

## Uninstalling

1. Move Prompteria from Applications to Trash
2. (Optional) Delete your data: `rm -rf ~/Library/Application\ Support/Prompteria`
