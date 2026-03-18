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
        "edgeIcons": {
            "enabled": true,
            "left": "",
            "opacity": 1,
            "right": "",
            "edgeInset": 2,
            "sectionGap": 14,
            "sectionGapLeft": 14,
            "sectionGapRight": 14
        },
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
        "animationMode": "balanced",
        "animationSpeed": 1,
        "radiusRatio": 1,
        "scaleRatio": 1,
        "screenRadiusRatio": 1,
        "shadowOffsetX": 2,
        "shadowOffsetY": 2,
        "themeVariant": "soft"
    }
}
```

### Theme Variant

Set `general.themeVariant` to choose your Gruvbox Material depth:

- `"soft"` (default): warm and softer contrast.
- `"medium"`: balanced contrast.
- `"hard"`: highest dark contrast.

Example:

```json
{
    "general": {
        "themeVariant": "hard"
    }
}
```

### Animation Profile

`general.animationMode` controls overall motion character while still honoring:

- `general.animationDisabled` (hard-off switch)
- `general.animationSpeed` (global multiplier)

Supported values:

- `"subtle"`: faster, less pronounced motion.
- `"balanced"` (default): polished but restrained.
- `"expressive"`: slightly slower, more visible transitions.

Example:

```json
{
    "general": {
        "animationMode": "subtle",
        "animationSpeed": 1.1
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

### Edge Icons

`bar.edgeIcons` controls the decorative symbols shown on the left and right side of the bar.

- `enabled`: show or hide both edge icons.
- `left`: left-side symbol/glyph.
- `right`: right-side symbol/glyph.
- `opacity`: icon capsule opacity from `0.0` to `1.0`.
- `edgeInset`: distance from the screen edge in px (smaller = closer to edge).
- `sectionGapLeft`: gap between left edge icon capsule and left widget group.
- `sectionGapRight`: gap between right edge icon capsule and right widget group.
- `sectionGap`: legacy fallback used when side-specific keys are not present.

Example:

```json
{
    "bar": {
        "edgeIcons": {
            "enabled": true,
            "left": "🐱",
            "right": "🌙",
            "opacity": 0.9,
            "edgeInset": 1,
            "sectionGapLeft": 24,
            "sectionGapRight": 18
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
