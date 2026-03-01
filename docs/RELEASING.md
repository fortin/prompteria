# Release Process

This document describes how to create and publish a new Promptastic release.

## First-Time Setup

Before your first release:

1. **Push to GitHub:** Create a repository and push your code
2. **Update URLs:** Replace `YOUR_USERNAME` in `README.md` and `docs/INSTALLATION.md` with your GitHub username or org
3. **Verify workflow:** The release workflow runs automatically on tag push—no secrets required

## Prerequisites

- [ ] Write access to the repository
- [ ] Git configured with your identity
- [ ] All changes committed and pushed

## Release Steps

### 1. Create version tag

```bash
# Ensure you're on main with latest changes
git checkout main
git pull origin main

# Create annotated tag (use semantic versioning: v1.0.0)
git tag -a v1.0.0 -m "Release v1.0.0"
```

### 2. Push tag to trigger GitHub Actions

```bash
git push origin v1.0.0
```

The [Release workflow](.github/workflows/release.yml) will:

1. Check out the code
2. Generate Xcode project with XcodeGen
3. Build the app in Release configuration
4. Create a DMG installer
5. Create a GitHub Release and attach the DMG

### 3. Verify and publish

1. Go to **Actions** tab and confirm the workflow completes
2. Go to **Releases** and find the new release
3. Edit the release to add:
   - Release notes (what's new, bug fixes, etc.)
   - Link to the full changelog if applicable

### 4. Announce

- Update the README if the version badge or links changed
- Announce on your preferred channels (Twitter, blog, etc.)

## Versioning

Use [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features, backward compatible
- **PATCH** (0.0.1): Bug fixes

## Troubleshooting

### Workflow fails: "xcodegen not found"

The workflow installs XcodeGen via Homebrew. If it fails, check the workflow file.

### Workflow fails: "Scheme not found"

Ensure `project.yml` has the `schemes` section and run `xcodegen generate` locally to verify.

### DMG not attached to release

- Check that the workflow completed successfully
- Verify the `build/` path and artifact names in the workflow
- Ensure `GITHUB_TOKEN` has sufficient permissions (default token has release write access)

### Users report "app is damaged"

This is Gatekeeper blocking unsigned apps. Users should:
1. Right-click the app
2. Select **Open**
3. Confirm in the dialog

Consider adding code signing and notarization for a smoother experience (requires Apple Developer account).
