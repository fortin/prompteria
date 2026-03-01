# Code Signing & Notarization Guide

This guide walks you through setting up code signing for both **direct distribution** (DMG on GitHub) and **Mac App Store** distribution.

## Overview

| Distribution | Certificate | Provisioning Profile | Notarization |
|--------------|-------------|----------------------|--------------|
| Direct (DMG) | Developer ID Application | Not required | Recommended |
| Mac App Store | Apple Distribution | Required | Handled by Apple |

---

## Part 1: Apple Developer Portal Setup

### 1.1 Create App ID (if not exists)

1. Go to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers** → **+** → **App IDs**
3. Select **App** → Continue
4. Description: `Promptastic`
5. Bundle ID: **Explicit** → `com.promptastic.app`
6. Capabilities: Enable **App Sandbox** (required for Mac App Store)
7. Register

### 1.2 Create Certificates

**Developer ID Application** (for direct distribution):

1. **Certificates** → **+** → **Developer ID Application** → Continue
2. Create CSR (Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority)
3. Upload CSR, Download certificate, Double-click to install in Keychain

**Apple Distribution** (for Mac App Store):

1. **Certificates** → **+** → **Apple Distribution** → Continue
2. Same CSR process, Download and install

**Developer ID Installer** (optional, for signing the DMG):

1. **Certificates** → **+** → **Developer ID Installer** → Continue
2. Same process

### 1.3 Create Mac App Store Provisioning Profile

1. **Profiles** → **+** → **Mac App Store** (under Distribution) → Continue
2. Select App ID: `com.promptastic.app` → Continue
3. Select **Apple Distribution** certificate → Continue
4. Profile Name: `Mac App Store com.promptastic.app` (or your choice)
5. Generate → Download → Double-click to install

**Important:** Note the exact profile name. You'll need it for `ExportOptions-appstore.plist`.

---

## Part 2: Project Configuration

### 2.1 Set Your Team ID

Edit `project.yml` and replace `YOUR_TEAM_ID` with your 10-character Team ID:

```yaml
DEVELOPMENT_TEAM: ABC123XYZ0  # Find in Xcode → Settings → Accounts
```

### 2.2 Update Provisioning Profile Name (Mac App Store only)

Edit `scripts/ExportOptions-appstore.plist` and set the profile name to match what you created:

```xml
<key>com.promptastic.app</key>
<string>Mac App Store com.promptastic.app</string>  <!-- Your profile name -->
```

---

## Part 3: Direct Distribution (DMG)

### 3.1 Build Signed DMG

```bash
./scripts/build-release.sh 1.0.0
```

This produces `build/Promptastic-1.0.0.dmg` signed with Developer ID.

### 3.2 Notarization

Notarization lets users open your app without right-click → Open. You need:

- **Apple ID** (your developer account email)
- **App-specific password** (create at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords)
- **Team ID** (if you have multiple teams)

```bash
export NOTARY_APPLE_ID="your@email.com"
export NOTARY_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password
export NOTARY_TEAM_ID="ABC123XYZ0"  # Optional, required for multiple teams

./scripts/build-release.sh 1.0.0
```

The script will submit the DMG to Apple, wait for notarization, and staple the ticket.

### 3.3 Verify Notarization

```bash
spctl -a -v -t install build/Promptastic-1.0.0.dmg
# Should show: accepted, source=Notarized Developer ID
```

---

## Part 4: Mac App Store

### 4.1 App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Platform: **macOS**
4. Name: **Promptastic**
5. Bundle ID: Select `com.promptastic.app`
6. Create

### 4.2 Export for Submission

```bash
./scripts/export-mas.sh
```

Output: `build/Promptastic-mas/` containing the signed app or pkg.

### 4.3 Upload

**Option A: Transporter app**

1. Install [Transporter](https://apps.apple.com/app/transporter/id1450874784) from Mac App Store
2. Drag the `.pkg` or `.app` from `build/Promptastic-mas/` into Transporter
3. Deliver

**Option B: Xcode Organizer**

1. Xcode → Window → Organizer
2. Select your archive → Distribute App
3. App Store Connect → Upload

**Option C: Command line**

```bash
xcrun altool --upload-app -f build/Promptastic-mas/Promptastic.pkg \
  -u your@email.com -p @keychain:AC_PASSWORD
```

---

## Part 5: Entitlements Reference

The app uses these entitlements (in `Promptastic.entitlements`):

| Entitlement | Purpose |
|-------------|---------|
| `com.apple.security.app-sandbox` | Required for Mac App Store; isolates app |
| `com.apple.security.files.user-selected.read-write` | Import/export via file dialogs |

---

## Troubleshooting

### "No signing certificate found"

- Ensure certificates are installed: Keychain Access → My Certificates
- Xcode → Settings → Accounts → Download Manual Profiles

### "Provisioning profile doesn't include the application-identifier"

- Regenerate the profile in Developer Portal
- Ensure App ID matches exactly: `com.promptastic.app`

### Notarization fails: "The binary uses an SDK older than"

- Update Xcode to the latest version
- Ensure deployment target in `project.yml` is current

### Notarization fails: "The signature of the binary is invalid"

- Ensure the app is signed before creating the DMG
- For DMG: sign with Developer ID Installer before notarizing
