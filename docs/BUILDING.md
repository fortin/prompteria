# Building Guide

This document is for contributors and maintainers who want to build Prompteria from source or create releases.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| Xcode 16+ | Build and run | [Mac App Store](https://developer.apple.com/xcode/) |
| XcodeGen | Generate Xcode project from `project.yml` | `brew install xcodegen` |
| create-dmg | Optional: nicer DMG with Applications link | `brew install create-dmg` |

## Project Structure

```
prompteria/
├── project.yml          # XcodeGen project spec (source of truth)
├── Prompteria/          # App source code
├── scripts/
│   └── build-release.sh
└── .github/workflows/
    └── release.yml
```

## Development Build

```bash
# Generate project (run after cloning or when project.yml changes)
xcodegen generate

# Open in Xcode
open Prompteria.xcodeproj

# Build and run: ⌘R
```

## Release Build

### Direct Distribution (DMG)

```bash
./scripts/build-release.sh [version]
```

- **With signing:** Requires Developer ID certificate. Produces signed, optionally notarized DMG.
- **Without signing:** Falls back to unsigned when no certificate is found (e.g. CI).

See [Code Signing](CODE_SIGNING.md) for full setup.

### Mac App Store

```bash
./scripts/export-mas.sh
```

Output: `build/Prompteria-mas/` containing the signed app or pkg for upload to App Store Connect.

Requires Apple Distribution certificate and Mac App Store provisioning profile. See [Code Signing](CODE_SIGNING.md).

### Code Signing

Signing is automatic when you have the Developer ID certificate installed. Configure `project.yml` with your Team ID and see [Code Signing](CODE_SIGNING.md) for notarization and Mac App Store setup.

## GitHub Releases

Releases are automated via GitHub Actions:

1. **Create release:** `git tag v1.0.0`
2. **Push tag:** `git push origin v1.0.0`
3. **Workflow runs:** Builds DMG and attaches to the GitHub Release

### Workflow Trigger

The workflow in `.github/workflows/release.yml` runs on any `v*` tag push (e.g. `v1.0.0`, `v2.1.3`).

### Release Checklist

- [ ] Update version in any user-facing docs
- [ ] Create and push tag: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] Verify release workflow completes
- [ ] Edit release on GitHub to add release notes
- [ ] Test the DMG on a clean machine
