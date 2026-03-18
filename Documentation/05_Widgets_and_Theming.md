# Widgets & Theming

Niruv is built with a robust theming system and a set of interactive widgets.

## 🎨 Theming System

Niruv uses **Gruvbox Material Dark** with runtime-selectable variants via `general.themeVariant`:

- `soft` (default)
- `medium`
- `hard`

The color system is designed to stay API-stable (`Color.m*`) while switching variants cleanly.

### Color Palette (`Commons/Color.qml`)

Colors are accessed via the `Color` singleton. We use Material Design 3 naming conventions (prefixed with `m`) to avoid conflicts with QML properties.

| Property | Description | Hex |
|----------|-------------|-----|
| `Color.mPrimary` | Primary accent (Green) | `#a9b665` |
| `Color.mSecondary` | Secondary accent (Yellow) | `#d8a657` |
| `Color.mTertiary` | Tertiary accent (Aqua) | `#89b482` |
| `Color.mOrange` | Orange accent | `#e78a4e` |
| `Color.mBlue` | Blue accent | `#7daea3` |
| `Color.mPurple` | Purple accent | `#d3869b` |
| `Color.mError` | Error state (Red) | `#ea6962` |
| `Color.mSurface` | Background color | `#32302f` |
| `Color.mOnSurface` | Text color | `#dab997` |

### Styling (`Commons/Style.qml`)

The `Style` singleton defines standard dimensions and animations:

- **Margins**: `Style.marginXS` (4px), `Style.marginS` (6px), `Style.marginM` (9px), `Style.marginL` (13px).
- **Radii**: `Style.radiusXS` (8px), `Style.radiusS` (12px), `Style.radiusM` (16px).
- **Animations**: `Style.animationFast` (150ms), `Style.animationNormal` (300ms).

Animation timing now also responds to `general.animationMode`:

- `subtle`: quicker, low-emphasis motion.
- `balanced` (default): polished and restrained.
- `expressive`: slower, more pronounced transitions.

`general.animationDisabled` remains the hard-off switch and `general.animationSpeed` remains the global multiplier.

## 🧱 Shared Panel Primitives

To keep panel code minimal and consistent, Niruv uses small shared primitives:

- `PanelPopup`: shared popup shell (anchor, lifecycle, implicit sizing).
- `PanelActionButton`: standard action rows used by multiple panels.
- `PanelStatusChip`: compact status badges (OFF/CONNECTED/IDLE).
- `PanelInfoPill`: tiny informational pills for secondary state hints.
- `PanelSurface`: shared panel shell surface (radius, border, shadow, content spacing).
- `SliderControl`: reusable slider row primitive for panel controls.
- `MetricRow`: reusable icon/label/value stat row primitive.

These primitives are intentionally small and explicit to preserve a suckless architecture.

## 🧩 Widgets

### Battery Widget

The battery widget is more than just a percentage indicator.

- **Hover Effect**: Expands to show a colored background (customizable theme color) and percentage text.
- **Left-Click**: Opens **BatteryPanel** with:
  - Battery percentage, time remaining, power draw, health
  - **Power Profile** buttons (Power Saver / Balanced / Performance)
  - Connected Bluetooth devices with battery levels
  - Button to open battery monitor
- **Bluetooth**: Automatically detects and displays battery levels for connected Bluetooth devices.

### Screen Recorder Widget

A minimalist screen recording tool integrated directly into the bar.

- **Status Indication**: Icon changes and background pulses red when recording.
- **Hover Expansion**: Expands to show "Record?" (idle) or "Recording..." (active) text on hover.
- **Direct Launch**: Clicking the icon instantly starts recording the screen (or prompts for region selection depending on configuration).
- **Smooth Animation**: Features smooth text expansion and color transitions.

### Workspace Widget

Displays Niri workspaces with smooth animations.

- **Active Indicator**: A pill-shaped indicator follows the active workspace.
- **Icons**: Supports Nerd Font icons for each workspace index.

### Clock Widget

A simple, elegant clock displaying the current time and date. Clicking it opens the **ClockPanel**.

- **ClockPanel**: Contains calendar cards and timer functionality
- **CalendarHeaderCard**: Displays the current day name, date, and month/year
- **CalendarMonthCard**: Full month grid with current day highlighted
- **TimerCard**: Timer/Stopwatch with Pomodoro presets

### Timer/Stopwatch (TimerCard)

Niruv includes a built-in timer accessible from the ClockPanel.

- **Countdown Mode**: Set custom duration and count down to zero
- **Stopwatch Mode**: Count up from zero (click stopwatch icon)
- **Pomodoro Presets**: Quick-start buttons for common intervals:
  - 25 minutes (Work session)
  - 5 minutes (Short break)
  - 15 minutes (Long break)
- **Customizable Alarm**: Change the sound by editing `Commons/Time.qml`:

  ```qml
  command: ["sh", "-c", "for i in 1 2 3; do paplay /path/to/your/sound.ogg; sleep 0.3; done"]
  ```

- **Bar Indicator**: Timer countdown appears in the center bar when running

### SystemMonitor Widget

Displays real-time system statistics in a compact capsule format.

- **CPU Usage**: Shows percentage with threshold warning (turns red when >80%)
- **RAM Usage**: Shows percentage with threshold warning (turns red when >80%)
- **CPU Temperature**: Displays in degrees, turns red when >80°C
- **Load Average**: Shows 1-minute system load
- **Hover Effect**: Capsule background turns blue on hover
- **Click Action**: Opens **SystemMonitorPanel** with detailed stats and progress bars
- **Service**: Uses `SystemStatService.qml` to poll `/proc/` filesystem every 3 seconds

### ActiveWindow Widget

Shows the currently focused window's icon and title.

- **Window Icon**: Displays the icon from the focused window's app-id
- **Window Title**: Shows truncated title (max 30 characters with ellipsis)
- **Auto-Hide**: Widget disappears when no window is focused
- **Hover Effect**: Capsule background turns primary color on hover
- **Niri Integration**: Polls `niri msg -j focused-window` every 500ms
- **Capsule Style**: Matches visual style of other bar widgets

### System Tray Widget

Displays system tray icons from applications using the Quickshell SystemTray API.

- **Icon Display**: Shows icons from nm-applet, blueman-applet, Discord, etc.
- **Capsule Style**: Icons displayed in a rounded capsule background
- **Left-Click**: Triggers the tray item's activate action
- **Right-Click**: Opens context menu popup (TrayMenu) with full menu support
- **Middle-Click**: Triggers secondary activate action if available
- **Scroll**: Scrolls up/down on the tray item
- **Submenu Support**: Context menus support nested submenus (hover to open)
- **Click-Outside-to-Close**: Integrates with PanelState for click-outside behavior
- **Auto-Hide**: Widget disappears when no tray items are present
- **Startup**: Tray apps like `nm-applet` and `blueman-applet` should be started via Niri config

### Wallpaper Widget

A quick wallpaper changer widget.

- **Click Action**: Sets a random wallpaper from `~/Pictures/Wallpapers` using `swaybg`
- **Supported Formats**: JPG, JPEG, PNG, WebP
- **Hover Effect**: Background pill appears on hover
- **Script**: Uses `oNIgiRI/bin/niri-random-wallpaper` for reliable process handling

### Volume Widget

Audio volume control with PipeWire integration.

- **Icon**: Changes based on volume level (muted, low, medium, high)
- **Hover Expansion**: Percentage text expands on hover after 500ms delay
- **Scroll Control**: Scroll up/down to adjust volume
- **Left-Click**: Opens **VolumePanel** with slider and device switching
- **Right-Click**: Opens external mixer (pwvucontrol/pavucontrol)
- **VolumePanel Features**:
  - Volume slider with visual feedback
  - Mute toggle in header
  - **Output Device switching** (when multiple devices available)
  - Quick button to open audio mixer
- **Service**: Uses `Services/Media/AudioService.qml` with Quickshell.Services.Pipewire

### Brightness Widget

Screen brightness control using brightnessctl.

- **Icon**: Changes based on brightness level (off, low, high)
- **Hover Expansion**: Percentage text expands on hover
- **Scroll Control**: Scroll up/down to adjust brightness (5% steps)
- **Left-Click**: Opens **BrightnessPanel** with slider and Night Light controls
- **Right-Click**: Set to 100%
- **BrightnessPanel Features**:
  - Brightness slider with visual feedback
  - Night Light section with Off/Auto/On mode buttons
- **Auto-Hide**: Widget only appears if brightnessctl is available
- **Service**: Uses `Services/Hardware/BrightnessService.qml`

### WiFi & Bluetooth Widgets

Network connectivity widgets with shared **NetworkPanel**.

- **WiFi Widget**: Shows connection status and SSID on hover
- **Bluetooth Widget**: Shows connection status and device name on hover
- **Left-Click** (either): Opens **NetworkPanel**
- **NetworkPanel Features**:
  - WiFi section: Toggle switch, SSID, "WiFi Settings" button (opens impala TUI)
  - Bluetooth section: Toggle switch, device name, "Bluetooth Settings" button (opens bluetui TUI)
  - Summary card: connection health + manual refresh + last update time
  - Status chips and info pills for clearer radio/link/device state

### Bar Edge Icons

Bar edge icons are configurable through `bar.edgeIcons`:

- `enabled`, `left`, `right`, `opacity`
- `edgeInset` (distance from screen edge)
- `sectionGapLeft`, `sectionGapRight` (spacing from left/right widget groups)

### Night Light Widget

Blue light filter toggle using wlsunset.

- **3-State Cycle**: Click cycles through Off → Auto → Forced → Off
- **Icon Changes**: Different icons for each state
- **Right-Click**: Toggle between Auto and Forced modes
- **Auto-Hide**: Widget only appears if wlsunset is installed
- **Service**: Uses `Services/System/NightLightService.qml`

## 🖱️ Panel Behavior

All popup panels share consistent behavior:

- **Click-Outside-to-Close**: Click anywhere outside the panel to close it
- **ESC Key**: Press Escape to close the panel
- **Auto-Close on New Panel**: Opening a new panel automatically closes any open panel
- **Single Lifecycle Owner**: `PanelPopup` owns popup visibility and transition state
- **PanelState Singleton**: Centralized routing/tracking via `Commons/PanelState.qml`
- **Press-Phase Backdrop Close**: Outside close is handled on pointer press in `shell.qml`

### Popup Flicker Regression Note

After an overhaul, Niruv had a close flicker caused by duplicated animation ownership:

- Shared popup shell (`PanelPopup`) and panel modules both animated visibility transitions.
- Backdrop close timing allowed a brief event race.

The fix was to keep popup lifecycle logic in one place (`PanelPopup`) and remove panel-local `root.visible` transition duplication. When extending panels, prefer animation on internal content details, not popup visibility state.

## ⚡ Performance Notes

- Bar widgets can be enabled/disabled via `Settings.data.bar.widgets`.
- Optional/heavy panel sections are lazy-loaded when panels become visible.
- Visualizer process runtime is tied to widget enablement.

## 📺 On-Screen Display (OSD)

Niruv displays visual feedback for system changes:

- **Volume OSD**: Appears when volume changes (shows icon + progress bar + percentage)
- **Brightness OSD**: Appears when brightness changes
- **Media OSD**: Appears when track changes (shows artist + title)
- **Position**: Top-right corner, below the bar
- **Auto-Hide**: Fades out after 2 seconds
- **Styling**: Gruvbox theme with smooth scale and fade animations
- **Muted State**: Volume OSD shows red progress bar when muted
