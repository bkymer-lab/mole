# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-23

### Added
- **Core:** Fully native macOS Swift app rewritten from scratch using modern SwiftUI.
- **Architecture:** Transitioned to Apple Silicon (M5) optimized multi-threading via Actor models.
- **XPC Daemon:** Secure privileged helper tool with audit token validation (`MoleDaemon`).
- **Engines:**
  - **Privacy Engine:** Thread-safe SQLite parser for Safari, Chrome, and Orion.
  - **Malware Protection Engine:** High-speed JSON rules matching for adware and threats.
  - **Cloud Cleanup Engine:** iCloud and Dropbox native file eviction using `NSFileManager`.
  - **Uninstaller Engine:** Deep scan capabilities targeting hidden cache, preference, and LaunchDaemon artifacts.
  - **Smart Updater:** Silent installation framework with DMG mounting capabilities.
  - **Smart Trash Monitor:** Background monitoring and live limits for Trash cleanup.
- **UI/UX:** Premium Glassmorphism design and Apple Human Interface Guidelines (HIG) compliance.
- **Deployment:** Drag-and-drop DMG packager, Code Signing, Hardened Runtime, and GitHub CI/CD automation.

### Removed
- Deprecated legacy Go-based CLI implementation.
- Removed outdated Bash testing and cleanup scripts.
