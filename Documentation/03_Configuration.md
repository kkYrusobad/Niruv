# Configuration

Niruv is highly customizable through its JSON-based settings system. This guide explains how to configure the shell.

## ⚙️ Settings Files

Niruv stores its configuration in the standard XDG config directory:

- **Settings**: `~/.config/niruv/settings.json`

The shell will automatically create this file with default values on the first run.

When upgrading from an older `settings.json`, Niruv will migrate missing keys (for example `bar.widgets`) by writing the new defaults on load.

### Settings Structure

The `settings.json` file follows this structure:

```json
{
    "bar": {
        "capsuleOpacity": 0.5,
        "density": "default",
        "enabled": true,
        "position": "top",
        "showCapsule": true,
        "widgets": {
            "activeWindow": true,
            "battery": true,
            "bluetooth": true,
            "brightness": true,
            "media": true,
            "nightLight": false,
            "screenRecorder": false,
            "systemMonitor": true,
            "tray": true,
            "visualizer": false,
            "volume": true,
            "wallpaper": false,
            "wifi": true,
            "workspace": true
        }
    },
    "general": {
        "animationDisabled": false,
        "animationSpeed": 1,
        "radiusRatio": 1,
        "scaleRatio": 1,
        "screenRadiusRatio": 1,
        "shadowOffsetX": 2,
        "shadowOffsetY": 2
    }
}
```

## 🖥️ Bar Configuration

You can customize the position and density of the bar.

### Widget Toggles

Use `bar.widgets` to enable or disable individual widgets without removing functionality from the shell.

Available widget keys:

- `workspace`
- `systemMonitor`
- `activeWindow`
- `tray`
- `wallpaper`
- `wifi`
- `bluetooth`
- `screenRecorder`
- `volume`
- `brightness`
- `nightLight`
- `battery`
- `media`
- `visualizer`

Example: disable heavy widgets for a lean setup

```json
{
    "bar": {
        "widgets": {
            "visualizer": false,
            "wallpaper": false,
            "screenRecorder": false,
            "media": true
        }
    }
}
```

### Position

Supported values: `"top"`, `"bottom"`, `"left"`, `"right"`.

### Density

Supported values:

- `"mini"`: Smallest size
- `"compact"`: Balanced size
- `"default"` (Recommended)
- `"comfortable"`: Larger elements and spacing

## 🌙 Night Light

Night light toggle uses `wlsunset`. Configuration for location/temp should be handled via user's `wlsunset` setup if applicable, though the shell provides a simple toggle.

## 🔧 Environment Variables

You can override certain paths and behaviors using environment variables:

- `NIRUV_DEBUG=1`: Enable debug logging and reload popups.
- `NIRUV_CONFIG_DIR`: Override the configuration directory (default: `~/.config/niruv/`).
- `NIRUV_CACHE_DIR`: Override the cache directory (default: `~/.cache/niruv/`).
