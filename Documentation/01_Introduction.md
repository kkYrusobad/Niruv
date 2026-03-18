# Introduction to Niruv

**Niruv** is a minimal, lightweight desktop shell built for the [Niri](https://github.com/YaLTeR/niri) Wayland compositor. It leverages the power of [Quickshell](https://quickshell.outfoxxed.me/) (Qt/QML) to provide a beautiful, responsive, and highly customizable user interface.

The name **Niruv** is a portmanteau of **Niri** and **Gruv**box, and also references the Sanskrit word **निरव** (*nirav*), meaning "quiet" or "silent." This reflects the shell's core design philosophy: to be unobtrusive, calm, and focused.

## ✨ Key Features

- **Minimalist Design**: A clean, distraction-free interface that stays out of your way.
- **Suckless Architecture**: Shared micro-primitives and explicit wiring over layered abstractions.
- **Lean by Default**: Optional/heavy widgets can be disabled while keeping all features available.
- **Gruvbox Material Theme**: Built from the ground up with the warm, retro-inspired Gruvbox Material Dark color scheme.
- **Responsive Bar**: A modular top bar containing essential widgets like workspaces, clock, media, and battery.
- **Interactive Widgets**:
  - **Workspaces**: Smoothly animated indicators for Niri workspaces.
  - **Clock**: Click to open ClockPanel with calendar and timer/stopwatch.
  - **Battery**: Detailed status with hover expansion and BatteryPanel popup.
  - **Media**: Track info with MediaPanel for full playback controls.
  - **System Monitor**: CPU/RAM/Temp/Load with SystemMonitorPanel for detailed stats.
- **Timer/Stopwatch**: Built-in timer with Pomodoro presets (25m, 5m, 15m) and customizable alarm sounds.
- **Click-Outside-to-Close**: All popup panels close when clicking outside or pressing ESC.
- **Floating Window Support**: Seamless integration with Niri's window rules for floating TUI applications.

## 🖼️ Gallery

Screenshots coming soon.

## 🚀 Getting Started

Niruv is designed to be easy to install and configure. Whether you are a seasoned Niri user or just getting started, this documentation will guide you through setting up your new shell.

- [Installation Guide](02_Installation.md)
- [Configuration](03_Configuration.md)
- [Architecture & Development](04_Architecture_and_Development.md)
- [Widgets & Theming](05_Widgets_and_Theming.md)
