<p align="center">
  <h1 align="center">निरव · Niruv</h1>
  <p align="center">
    <em>A minimal, Gruvbox-themed desktop shell for Niri</em>
  </p>
</p>

<div align="center">

<https://github.com/user-attachments/assets/da7172b0-9a61-4387-8d6a-9b5da72b2cd6>

</div>

---

**Niruv** is a lightweight desktop shell built on [Quickshell](https://quickshell.outfoxxed.me/) (Qt/QML) for the [Niri](https://github.com/YaLTeR/niri) Wayland compositor.

The name combines **Niri** + **Gruv**box, and references the Sanskrit word **निरव** (*nirav*) — meaning "quiet" or "silent" — reflecting the shell's minimal, unobtrusive design philosophy.

## 🧠 Suckless-First Philosophy

Niruv follows a practical "suckless" approach: keep behavior explicit, remove duplication first, and avoid abstractions that do not pay for themselves.

- **One clear way to do things**: shared panel primitives and consistent popup behavior.
- **Lazy by default**: optional/heavy widgets are loaded only when enabled.
- **Fewer moving parts**: consolidated polling and service timers where possible.
- **Backwards-safe evolution**: new settings include compatibility fallbacks for existing users.

This keeps startup lighter, maintenance simpler, and feature parity intact.

## ✨ Features

- 🎨 **Gruvbox Material Dark** with `soft` / `medium` / `hard` variants
- 🖥️ **Workspace indicators** with Nerd Font icons and smooth animations
- 📊 **System Monitor** showing CPU%, RAM%, temperature, and load average with threshold alerts
- 🪟 **Active Window** shows focused window icon and title
- 🖼️ **Wallpaper widget** click to set random wallpaper via swaybg
- 🔋 **Battery widget** with hover effects, themed expansion, BatteryPanel with power profile controls
- 🎥 **Screen Recorder** with recording status, hover expansion, and direct launch
- 📶 **WiFi widget** with SSID display on hover, click opens NetworkPanel
- 🔵 **Bluetooth widget** with connected device display, click opens NetworkPanel
- 🎵 **Media widget** showing current track (Artist - Title), with MediaPanel popup (album art background)
- 🎼 **Cava Visualizer** integrated audio spectrum display
- 🔊 **Volume widget** with VolumePanel popup, audio device switching, scroll to adjust
- ☀️ **Brightness widget** with BrightnessPanel popup including Night Light controls
- 🌙 **Night Light widget** with wlsunset toggle (off → auto → forced states)
- 🕐 **Clock widget** with ClockPanel popup containing calendar and timer
- ⏱️ **Timer/Stopwatch** with Pomodoro presets, customizable alarm sound
- 📅 **Calendar Cards** displaying current date and month grid
- ⌨️ **JetBrainsMono Nerd Font** throughout
- 🚀 **Minimalist Launcher** with app search + system menu (Tab to switch modes)
- 🖱️ **Click-outside-to-close** panels - click anywhere outside or press ESC
- 📺 **On-Screen Display (OSD)** visual feedback for volume/brightness/media changes
- 🎬 **Animation profiles** with `subtle` / `balanced` / `expressive` motion modes
- ⚡ **Power Profiles** switch between Performance/Balanced/Power Saver modes
- 🔔 **System Tray** displays tray icons with right-click context menus

### Minimal Architecture Highlights

- Shared panel shell via `Commons/PanelPopup.qml` used across major panels.
- Shared micro-components (`PanelActionButton`, `PanelStatusChip`, `PanelInfoPill`) reduce repeated QML blocks.
- Shared panel primitives (`SliderControl`, `MetricRow`, `PanelSurface`) keep panels explicit but DRY.
- Bar edge icons support independent side spacing via `bar.edgeIcons.sectionGapLeft` and `sectionGapRight`.
- Single heartbeat stats polling in `Services/System/SystemStatService.qml`.
- Launcher apps are lazily loaded and cached in `Services/System/ApplicationsService.qml`.
- Bar widgets are toggleable through `bar.widgets` with loader-based instantiation in `Modules/Bar/Bar.qml`.

## 📚 Documentation

For detailed guides on installation, configuration, and development, please refer to the full documentation:

- [**Introduction**](Documentation/01_Introduction.md)
- [**Installation Guide**](Documentation/02_Installation.md)
- [**Configuration**](Documentation/03_Configuration.md)
- [**Architecture & Development**](Documentation/04_Architecture_and_Development.md)
- [**Widgets & Theming**](Documentation/05_Widgets_and_Theming.md)

## 📦 Requirements

| Dependency | Description |
|------------|-------------|
| [quickshell](https://quickshell.outfoxxed.me/) | Qt/QML shell framework |
| [niri](https://github.com/YaLTeR/niri) | Scrollable-tiling Wayland compositor |
| JetBrainsMono Nerd Font | Icon and text rendering |
| power-profiles-daemon | (Optional) Power profile switching |

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/kkYrusobad/Nirav.git
cd Nirav/Niruv

# Run the install script
./install.sh

# Start the shell
qs -c niruv
```

The install script will:

- Check and optionally install dependencies
- Create config directories (`~/.config/niruv`, `~/.cache/niruv`)
- **Automatically configure project root in `settings.json`**
- Create Quickshell symlink
- Optionally install [oNIgiRI](https://github.com/kkYrusobad/oNIgiRI) menu scripts

For manual setup or more details, see the [Documentation](Documentation/02_Installation.md).

### Automatic Project Detection

Niruv automatically detects and configures its project root during installation. The install script writes the project path to `~/.config/niruv/settings.json`, ensuring oNIgiRI scripts and other features work out of the box.

If needed, you can override this via environment variable:

```bash
export NIRUV_PROJECT_DIR="/path/to/your/niruv-folder"
qs -c niruv
```

## 🎛️ Customization

Niruv can be configured without editing the source code via a JSON configuration file.

### Configuration File

The shell will automatically create a default configuration at:
`~/.config/niruv/settings.json`

You can customize the bar position, density, workspace icons, and more. Changes to this file are applied **instantly** (live-reloaded).

### Example Settings

```json
{
  "general": {
    "projectRoot": "/path/to/noctaliaChange/",
    "themeVariant": "soft",
    "animationMode": "balanced",
    "scaleRatio": 1.0,
    "animationSpeed": 1.0
  },
  "bar": {
    "position": "top",
    "density": "default",
    "showCapsule": true
  }
}
```

### Manual Source Edits

If you need to change something not yet in the JSON config, you can still edit the QML files. For example, to change workspace icons, edit `Modules/Bar/Widgets/Workspace.qml`.

## 🔧 oNIgiRI Integration

Niruv integrates with [oNIgiRI](https://github.com/kkYrusobad/oNIgiRI) to provide system menu functionality:

- 📸 **Screenshot utilities** - region capture, fullscreen, clipboard
- 🌙 **Screensaver & night light** - toggle controls
- 📦 **Package management** - pacman, AUR installers
- 🌐 **App installers** - create web apps and TUI apps
- ⚙️ **System controls** - WiFi, Bluetooth, power profiles

The launcher (accessible via IPC or keybinding) provides two modes:

- **Apps Mode** (  ): Search and launch desktop applications
- **Menu Mode** ( 󰄛 ): Access oNIgiRI system menu categories

Press **Tab** to switch between modes. Scripts are automatically configured during installation, with the bin path resolved from `settings.json`.

## 📁 Project Structure

```
niruv/
├── shell.qml                  # Entry point
├── Commons/                   # Core singletons
│   ├── Color.qml              # Gruvbox color palette
│   ├── Style.qml              # UI design tokens
│   ├── Logger.qml             # Debug logging
│   ├── Time.qml               # Clock + Timer utilities
│   ├── Settings.qml           # Configuration
│   └── PanelState.qml         # Panel visibility tracking (click-outside-to-close)
├── Modules/
│   ├── Bar/                   # Top bar module
│   │   ├── Bar.qml            # Main bar component
│   │   └── Widgets/
│   │       ├── Workspace.qml  # Workspace indicators
│   │       ├── SystemMonitor.qml # CPU/RAM/Temp/Load display
│   │       ├── ActiveWindow.qml  # Focused window icon + title
│   │       ├── Wallpaper.qml  # Random wallpaper setter
│   │       ├── Battery.qml    # Battery status widget
│   │       ├── ScreenRecorder.qml # Screen recording widget
│   │       ├── WiFi.qml       # WiFi status widget
│   │       ├── Bluetooth.qml  # Bluetooth status widget
│   │       ├── Media.qml      # Media player widget
│   │       ├── Visualizer.qml # Cava audio visualizer
│   │       ├── Volume.qml     # Volume control widget
│   │       ├── Brightness.qml # Brightness control widget
│   │       ├── NightLight.qml # Night light toggle widget
│   │       ├── Tray.qml       # System tray icons widget
│   │       └── TrayMenu.qml   # Tray context menu popup
│   ├── Cards/                 # Reusable card components
│   │   ├── CalendarHeaderCard.qml  # Current date display
│   │   ├── CalendarMonthCard.qml   # Month grid calendar
│   │   └── TimerCard.qml      # Timer/Stopwatch with Pomodoro presets
│   ├── Panels/                # Popup panels
│   │   ├── ClockPanel/        # Calendar + Timer panel
│   │   ├── BatteryPanel/      # Detailed battery info
│   │   ├── MediaPanel/        # Full media controls
│   │   ├── VolumePanel/       # Volume slider + mute toggle
│   │   ├── BrightnessPanel/   # Brightness slider + Night Light
│   │   ├── NetworkPanel/      # WiFi + Bluetooth controls
│   │   └── SystemMonitorPanel/ # Detailed system stats
│   └── Launcher/              # App Launcher + System Menu
│       └── Launcher.qml       # Minimalist launcher UI
│   └── OSD/                   # On-Screen Display
│       └── OSD.qml            # Volume/brightness/media OSD overlay
└── Services/
    ├── Compositor/
    │   └── NiriService.qml    # Niri IPC integration
    ├── Hardware/
    │   ├── BatteryService.qml    # Battery icon logic
    │   └── BrightnessService.qml # Brightness control via brightnessctl
    ├── Media/
    │   ├── CavaService.qml       # Cava audio visualizer service
    │   └── AudioService.qml      # PipeWire audio volume/mute + device switching
    ├── Networking/
    │   └── BluetoothService.qml # Bluetooth battery support
    ├── Power/
    │   └── PowerProfileService.qml # Performance/Balanced/Power Saver modes
    ├── System/
    │   ├── ApplicationsService.qml  # App listing + search
    │   ├── MenuService.qml          # System menu categories + actions
    │   ├── SystemStatService.qml    # CPU/RAM/Temp/Load stats
    │   └── NightLightService.qml    # wlsunset night light control
    └── UI/
        └── ToastService.qml   # Desktop notifications
```

## 🔧 Troubleshooting

### oNIgiRI Scripts Not Working

If screenshot, screensaver, or other menu scripts don't execute:

1. **Verify projectRoot** - Check that `~/.config/niruv/settings.json` contains:

   ```json
   {
     "general": {
       "projectRoot": "/full/path/to/noctaliaChange/"
     }
   }
   ```

   The path should point to the parent directory containing both `Niruv/` and `oNIgiRI/` folders.

2. **Restart Quickshell** - Changes to settings require a restart:

   ```bash
   killall qs && qs -c niruv
   ```

3. **Check script permissions** - Ensure oNIgiRI scripts are executable:

   ```bash
   chmod +x oNIgiRI/bin/*
   ```

### Manual projectRoot Configuration

If automatic detection fails during installation, manually edit `~/.config/niruv/settings.json` and add the `projectRoot` property as shown above.

## 🙏 Acknowledgments

- [Noctalia Shell](https://github.com/nicholasswift/noctalia-shell) — Inspiration for animation patterns
- [Gruvbox](https://github.com/morhetz/gruvbox) — Color scheme

## 📄 License

MIT
