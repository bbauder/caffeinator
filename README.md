<p align="center">
  <img src="Screenshots/AppIcon.png" width="128" alt="Caffeinator App Icon">
</p>

# **Caffeinator**

Caffeinator is a small, unobtrusive menu bar utility that keeps your Mac awake when you need it. It launches at login and blends into the background, displaying at‑a‑glance status with a subtle animated icon, clear activity labels, and optional notifications — all with minimal clicks and a modern, native macOS design.

---

## Features

- **One‑Click Activation** — Streamlined controls designed for common keep‑awake workflows with minimal clicks.
- **Smart Durations** — Choose from quick presets or set a custom timer.
- **Recent Durations** — Your most‑used durations surface automatically for faster access.
- **At‑a‑Glance Status** — A subtle animated icon and clear activity labels make it obvious when Keep Awake is active.
- **Optional Notifications** — Alerts for timer completion, app‑based activation changes, and Auto‑Disable events.
- **App‑Based Activation** — Automatically stay awake while selected apps are running.
- **Launch at Login** — Always available when you need it, with a simple toggle in Settings.
- **Universal Binary** — Runs natively on both Apple Silicon and Intel Macs.
- **Privacy‑Respecting** — No ads, no telemetry, no network access, and no data collection of any kind.

---

## Installation

### Download

Grab the latest notarized release from GitHub:

➡️ **[Download Caffeinator](https://github.com/bbauder/caffeinator/releases/latest)**

You’ll receive a file named **Caffeinator.zip**.

### Install

1. Unzip the file  
2. Drag **Caffeinator.app** into your **/Applications** folder  
3. Launch it from Applications  
4. (Optional) Enable **Launch at Login** in Settings  

## Installation via Homebrew

[![Homebrew Tap](https://img.shields.io/badge/Homebrew-Tap-blue)](https://github.com/bbauder/homebrew-caffeinator)

You can install Caffeinator using Homebrew:

```sh
brew tap bbauder/caffeinator
brew install caffeinator
```
Note: On first launch, macOS will show a standard Gatekeeper confirmation dialog because Caffeinator is distributed outside the App Store. The app is fully signed, notarized, and stapled by Apple.

---

## Requirements

- **macOS 14 Sonoma or later**  
- **Intel or Apple Silicon**  

Caffeinator uses modern Swift concurrency features (`MainActor.assumeIsolated`) that require Sonoma or newer.

---

## Security & Trust

Caffeinator is production‑grade:

- Signed with a **Developer ID Application** certificate  
- Notarized by Apple  
- Stapled for offline verification  
- Fully Gatekeeper‑compatible  

Verify the signature manually:
```
spctl -v --assess --type exec /Applications/Caffeinator.app
```

Expected output:  
`accepted`  
`source=Notarized Developer ID`

---

## Screenshots

### Inactive
![Inactive](Screenshots/Inactive.png)

### Inactive — Full Menu
![Inactive Full Menu](Screenshots/Inactive-full-menu-cascaded.png)

### Active — Indefinite Mode
![Active Indefinite](Screenshots/Active-indefinite-mode.png)

### Active — Counting Down
![Active Countdown](Screenshots/Active-counting-down.png)

### Active — Watching Apps (Tooltip)
![Active Watching Apps](Screenshots/Active-watching-apps-tooltip-visible.png)

### Keep Awake Until
![Keep Awake Until](Screenshots/Keep-Awake-Until-popover.png)

### Custom Duration
![Custom Duration](Screenshots/Custom-Duration-popover.png)

### Watch Processes
![Watch Processes](Screenshots/Watch-Processes-dialog.png)

---

<details>
<summary><strong>More Screenshots</strong></summary>
<br>

### Active — Countdown with Menu
![Active Countdown Menu](Screenshots/Active-counting-down-menu-visible.png)

### Settings
![Settings](Screenshots/Settings-dialog.png)

### Settings (Scrolled)
![Settings Bottom](Screenshots/Settings-scrolled-to-bottom.png)

</details>

---

## Development

Caffeinator is built with:

- Swift 5.10+  
- SwiftUI  
- Xcode 26.5  
- Modern macOS APIs  
- A clean, modular MVVM architecture  

The workspace includes **162 unit tests**, and all user‑facing strings are localized into **23 languages**.

---

## Building from Source

Clone the repo:
```
git clone https://github.com/bbauder/caffeinator.git
```

Open the workspace in Xcode and build the **Caffeinator** target.

---

## 📄 License

Released under the [MIT License](LICENSE).

---

## 🙌 Acknowledgments

Caffeinator is inspired by the simplicity of classic “keep awake” utilities, but built from scratch with modern SwiftUI, a clean architecture, and a focus on simple workflows and UX.
