<p align="center">
  <img src="Screenshots/AppIcon.png" width="128" alt="Caffeinator App Icon">
</p>

# **Caffeinator**
A polished, lightweight, native macOS menu bar utility to keep your Mac awake when you want, and without fuss.

---

## Features

- **Menu Bar Control** — One click to keep your Mac awake.
- **Smart Durations** — Choose from presets or set a custom timer.
- **Watched Apps** — Automatically stay awake while selected apps are running.
- **MRU Durations** — Your most-used durations appear automatically.
- **Animated Icon** — Subtle animation runs while Keep Awake is active, for easy at-a-glance status.
- **Launch at Login** — Optional and fully sandbox‑compliant.
- **Universal Binary** — Runs natively on both Apple Silicon and Intel Macs.
- **Privacy‑Respecting** — No ads, no telemetry, no network access, no data collection of any kind.
- **Optional Notifications** — Get alerts when a timer ends, a watched app exits, or Auto‑Disable triggers.

---

## Installation

### Download

Grab the latest notarized release from GitHub:

➡️ **[Download Caffeinator](https://github.com/bbauder/caffeinator/releases/latest)**

You’ll receive a file named: Caffeinator.zip

### Install

1. Unzip the file  
2. Drag **Caffeinator.app** into your **/Applications** folder  
3. Launch it from Applications  
4. (Optional) Enable **Launch at Login** in Settings  

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
- Gatekeeper‑friendly  

You can verify the signature manually:
```
spctl -v --assess --type exec /Applications/Caffeinator.app
```
Expected output:<br>
accepted<br>
source=Notarized Developer ID<br>

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

### Active — Watching Apps w/ToolTip
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

### Settings Cont'd
![Settings Bottom](Screenshots/Settings-scrolled-to-bottom.png)

</details>

---

## Development

Caffeinator is built with:
- Swift 5.10+  
- SwiftUI  
- Xcode 26.5  
- Modern macOS APIs  
- A clean, modular architecture built on the MVVM (Model-View-ViewModel) pattern

The project structure follows a modern layout emphasizing clear separation of concerns.<br>
The workspace contains 162 unit tests.<br>
User-facing strings have been localized into 23 different locales.<br>

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
