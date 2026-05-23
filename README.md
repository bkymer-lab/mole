<div align="center">
  <img src="https://raw.githubusercontent.com/bilalyasinyaman/mole-main/main/MacApp/Assets.xcassets/AppIcon.appiconset/mac1024.png" width="128" height="128" alt="Mole Logo">
  
  # Mole for macOS
  ### The Premium System Cleaner & Optimization Suite
  
  [![Swift 5.10](https://img.shields.io/badge/Swift-5.10-F05138.svg?style=for-the-badge&logo=swift)](https://swift.org)
  [![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-000000.svg?style=for-the-badge&logo=apple)](https://apple.com/macos)
  [![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1_to_M5-000000.svg?style=for-the-badge&logo=apple)](https://apple.com)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
</div>

---

**Mole** is a state-of-the-art macOS system cleaner and maintenance utility built strictly within Apple Human Interface Guidelines (HIG). Engineered with absolute precision, it takes full advantage of the advanced **Apple Silicon (M1-M5) architecture** using highly concurrent, actor-based asynchronous paradigms.

Mole stands shoulder-to-shoulder with the most premium utilities on the market (e.g., CleanMyMac 5) by offering a frictionless, visually stunning, and blisteringly fast macOS maintenance experience.

## ✨ Signature Features

### 🚀 Smart Scan Engine
Mole doesn't just look for junk. Our intelligent scanning engine safely estimates reclaimable space instantly without blocking the UI, identifying caches, logs, and leftovers.

### 🧹 Deep Uninstaller
Dragging an app to the Trash is never enough. The **Deep Uninstaller** crawls through your library:
- `~/Library/Application Support`
- `~/Library/Caches`
- `~/Library/Preferences`
- `/Library/LaunchDaemons`
It finds every leftover plist, daemon, and hidden cache file to completely eradicate unwanted applications.

### 🔭 Space Lens
Visualize your storage elegantly. The Space Lens feature maps your disk structure into a beautiful, interactive bubble map, letting you spot massive, forgotten files at a single glance. Rendered smoothly using native SwiftUI Canvas elements.

### 🔐 Privacy & SQLite Engine
Using an autonomous SQLite parser, Mole deeply and safely cleans up browsing history, tracking cookies, and offline data across major browsers (Safari, Chrome, Orion) without risking database corruption.

### ⚡ Apple Silicon First (Actor-Based Concurrency)
Every core module in Mole is built on modern **Swift Concurrency (`async/await` & `actor`)**. It shifts heavy IO tasks (like folder traversal and disk calculations) to background threads, guaranteeing that the Glassmorphism UI never stutters, even on massive storage drives.

## 🎨 Premium UI & Onboarding
- **Glassmorphism Design:** Subtle materials, spring animations, and hovering pulse effects make using Mole an absolute delight.
- **Trust-first Permissions Flow:** Mole doesn't blind-ask for permissions. Our onboarding clearly explains *why* Full Disk Access and Notifications are needed through a beautifully interactive native workflow.

## 🛠 Architecture & Tech Stack

- **Frontend:** 100% SwiftUI with custom `VisualEffectView` wrappers for `NSVisualEffectView` materials.
- **Backend / Daemon:** Secure `MoleDaemon` (XPC Service) utilizing `auditToken` and `SecCodeCopySigningInformation` for un-spoofable root-level privileges.
- **CI/CD:** Automated GitHub Actions pipeline. On every tag push, Mole is built in Release Mode (`-O -wmo`) and packaged into a beautiful drag-and-drop `.dmg` file via an autonomous shell script.
- **Security:** Full Hardened Runtime and Notarization-ready Entitlements out of the box.

## 📦 Installation (Release Builds)

1. Navigate to the **[Releases](#)** tab.
2. Download the latest `Mole_Premium.dmg`.
3. Open the `.dmg` and drag Mole to your `Applications` folder.

## 🏗 Building from Source

To build Mole locally, ensure you are running Xcode 15+ and macOS 14.0+.

```bash
# Clone the repository
git clone https://github.com/bilalyasinyaman/mole-main.git
cd mole-main/MacApp

# Run the Production Packager Script
./Scripts/build_release_dmg.sh
```

The script will clean the build environment, inject release-level optimizations, sign the binary with Hardened Runtime entitlements, and generate your Drag-and-Drop `Mole_Premium.dmg` ready for distribution.

---

<div align="center">
  <i>Built with uncompromising standards for the modern Mac.</i>
</div>
