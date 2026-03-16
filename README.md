# MyMouser — MX Master 3S Button Remapper for macOS

A lightweight, open-source, fully local Swift/SwiftUI alternative to **Logitech Options+** for remapping every programmable button on the **Logitech MX Master 3S** mouse on macOS.

No telemetry. No cloud. No Logitech account required.

## Features

- **macOS native** — Built with Swift and SwiftUI, using CGEventTap for mouse hooking, Quartz CGEvent for key simulation, and NSWorkspace for app detection
- **Remap all 6 programmable buttons** — middle click, gesture button, back, forward, horizontal scroll left/right
- **Per-application profiles** — automatically switch button mappings when you switch apps (e.g., different bindings for Safari vs. VS Code)
- **22 built-in actions** across navigation, browser, editing, and media categories
- **DPI / pointer speed control** — slider from 200–8000 DPI with quick presets, synced to the device via HID++
- **Scroll direction inversion** — independent toggles for vertical and horizontal scroll
- **Gesture button support** — full HID++ 2.0 divert on Bluetooth (no Logitech software needed)
- **Battery monitor** — reads battery level via HID++ on connect and refreshes every 5 minutes
- **Auto-reconnection** — automatically detects when the mouse is turned off/on or disconnected/reconnected
- **Live connection status** — the UI shows a real-time "Connected" / "Not Connected" badge
- **Modern SwiftUI** — dark theme with interactive mouse diagram and per-button action picker
- **System tray** — runs in background, hides to tray on close, toggle remapping on/off from tray menu
- **Zero external services** — config is a local JSON file, all processing happens on your machine

## Supported Device

| Property | Value |
|---|---|
| Device | Logitech MX Master 3S |
| Product ID | `0xB034` |
| Protocol | HID++ 4.5 (Bluetooth) |
| Connection | Bluetooth (USB receiver also works for basic buttons) |

> **Note:** The architecture is designed to be extensible to other Logitech HID++ mice, but only the MX Master 3S is tested.

## Default Mappings

| Button | Default Action |
|---|---|
| Back button | Cmd + Tab (Switch Windows) |
| Forward button | Cmd + Tab (Switch Windows) |
| Middle click | Pass-through |
| Gesture button | Pass-through |
| Horizontal scroll left | Browser Back |
| Horizontal scroll right | Browser Forward |

## Available Actions

| Category | Actions |
|---|---|
| **Navigation** | Cmd+Tab, Cmd+Shift+Tab, Mission Control (Ctrl+Up) |
| **Browser** | Back, Forward, Close Tab (Cmd+W), New Tab (Cmd+T) |
| **Editing** | Copy, Paste, Cut, Undo, Select All, Save, Find |
| **Media** | Volume Up, Volume Down, Volume Mute, Play/Pause, Next Track, Previous Track |
| **Other** | Do Nothing (pass-through) |

## Requirements

- macOS 12.0+ (Monterey)
- Logitech MX Master 3S paired via Bluetooth or USB receiver
- **Accessibility permission required** — System Settings → Privacy & Security → Accessibility
- **Logitech Options+ must NOT be running** (it conflicts with HID++ access)

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 12.0+ SDK

### Steps

```bash
# Clone or navigate to the project
cd MyMouser

# Build using the provided script
./build.sh

# Or open in Xcode and build
open MyMouser.xcodeproj
```

The built app will be at:
```
build/DerivedData/Build/Products/Debug/MyMouser.app
```

## Installation

1. Build the project using Xcode or the build script
2. Copy `MyMouser.app` to your `/Applications` folder
3. Launch the app
4. Grant **Accessibility permission** when prompted (System Settings → Privacy & Security → Accessibility)
5. The app will appear in the system tray (menu bar)

## Usage

- Click the tray icon to open settings
- Click any hotspot dot on the mouse diagram to configure its action
- Create per-app profiles from the left panel
- Adjust DPI and scroll settings in the "Point & Scroll" tab
- Close the window to hide to tray (app keeps running)
- Right-click tray icon to toggle remapping or quit

## Project Structure

```
MyMouser/
├── MyMouser/
│   ├── Core/                    # Backend logic
│   │   ├── Config.swift         # Configuration manager
│   │   ├── AppDetector.swift    # Foreground app detection
│   │   ├── KeySimulator.swift   # Key event simulation
│   │   ├── MouseHook.swift      # CGEventTap mouse hook
│   │   ├── HIDGesture.swift     # HID++ gesture button support
│   │   └── Engine.swift         # Core orchestrator
│   ├── UI/                      # SwiftUI interface
│   │   ├── MainView.swift       # Main window with sidebar
│   │   ├── MousePage.swift      # Mouse configuration page
│   │   ├── ScrollPage.swift     # DPI and scroll settings
│   │   ├── ActionChip.swift     # Action selection chip
│   │   ├── HotspotDot.swift     # Interactive mouse hotspot
│   │   ├── Theme.swift          # Color and style definitions
│   │   ├── Backend.swift        # UI-backend bridge
│   │   └── Font+Extension.swift # Font utilities
│   ├── Resources/               # Assets
│   │   └── Assets.xcassets/     # App icons and images
│   ├── MyMouserApp.swift        # App entry point
│   ├── Info.plist               # App configuration
│   └── MyMouser.entitlements    # Security entitlements
└── README.md
```

## Architecture

```
┌─────────────┐     ┌──────────┐     ┌────────────────┐
│  Mouse HW   │────▶│ Mouse    │────▶│ Engine         │
│ (MX Master) │     │ Hook     │     │ (orchestrator) │
└─────────────┘     └──────────┘     └───────┬────────┘
                         ▲                    │
                    block/pass           ┌────▼────────┐
                                         │ Key         │
┌─────────────┐     ┌──────────┐        │ Simulator   │
│ SwiftUI     │◀───▶│ Backend  │        │ (CGEvent)   │
│ Interface   │     │ (Bridge) │        └─────────────┘
└─────────────┘     └──────────┘
                         ▲
                    ┌────┴────────┐
                    │ App         │
                    │ Detector    │
                    └─────────────┘
```

## Known Limitations

- **MX Master 3S only** — HID++ feature indices and CIDs are hardcoded for this device (PID `0xB034`)
- **Bluetooth recommended** — HID++ gesture button divert works best over Bluetooth; USB receiver has partial support
- **Conflicts with Logitech Options+** — both apps fight over HID++ access; quit Options+ before running MyMouser
- **Accessibility permission required** — macOS requires this for CGEventTap to intercept mouse events

## Future Work

- [ ] Support more Logitech HID++ mice (MX Master 3, MX Anywhere 3, etc.)
- [ ] Custom key combos — let users define arbitrary key sequences
- [ ] Start with macOS — autostart via LaunchAgents
- [ ] Gesture button swipe actions — up/down/left/right for multi-action gestures
- [ ] Export/import config — share configurations between machines
- [ ] Tray icon badge — show active profile name in tray tooltip

## License

This project is licensed under the MIT License.

## Acknowledgments

Based on the original [Mouser](https://github.com/TomBadash/MouseControl) project by TomBadash.

**MyMouser** is not affiliated with or endorsed by Logitech. "Logitech", "MX Master", and "Options+" are trademarks of Logitech International S.A.
