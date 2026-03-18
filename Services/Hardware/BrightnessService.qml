pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * BrightnessService - Screen brightness control singleton
 * Uses brightnessctl for backlight control
 */
Singleton {
  id: root

  // Signal for OSD (using 'Updated' to avoid conflict with property change signal)
  signal brightnessUpdated()

  // Current brightness level (0.0 - 1.0)
  property real brightness: 0.5

  // Flag to suppress OSD during internal changes (like AudioService)
  property bool isSettingBrightness: false

  // Only emit signal for external changes (from brightnessctl/function keys)
  onBrightnessChanged: {
    if (!isSettingBrightness) {
      brightnessUpdated();
    }
  }

  // Whether brightness control is available
  property bool available: false

  // Step size for increase/decrease (5%)
  readonly property real stepSize: 0.05

  // Minimum brightness to prevent complete blackout
  readonly property real minBrightness: 0.01

  // Poll for external brightness changes (from function keys or brightnessctl)
  Timer {
    id: pollTimer
    interval: 400
    repeat: true
    running: root.available
    onTriggered: refreshBrightness()
  }

  // Initialize on startup
  Component.onCompleted: {
    refreshBrightness();
  }

  // Refresh brightness from system
  function refreshBrightness() {
    if (!refreshProcess.running) {
      refreshProcess.running = true;
    }
  }

  // Get current brightness
  Process {
    id: refreshProcess
    command: ["brightnessctl", "-m"]
    stdout: SplitParser {
      onRead: data => {
        // brightnessctl -m format: device,class,current,percent,max
        // Example: intel_backlight,backlight,500,50%,1000
        var parts = data.split(",");
        if (parts.length >= 4) {
          var percentStr = parts[3].replace("%", "");
          var percent = parseInt(percentStr);
          if (!isNaN(percent)) {
            root.brightness = percent / 100.0;
            root.available = true;
          }
        }
      }
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.available = false;
        Logger.w("BrightnessService", "brightnessctl not available");
      }
    }
  }

  // Set brightness process
  Process {
    id: setBrightnessProcess
    property string targetValue: "50%"
    command: ["brightnessctl", "s", targetValue]
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        refreshBrightness();
      }
    }
  }

  // Set brightness (0.0 - 1.0)
  function setBrightness(value: real) {
    if (!available) return;
    
    // Clamp value
    value = Math.max(minBrightness, Math.min(1.0, value));
    
    // Set flag to suppress OSD for internal changes
    isSettingBrightness = true;
    
    // Update local state immediately for responsive UI
    brightness = value;
    
    // Set via brightnessctl
    var percent = Math.round(value * 100);
    setBrightnessProcess.targetValue = percent + "%";
    setBrightnessProcess.running = true;
    
    // Clear flag after a short delay
    Qt.callLater(() => { isSettingBrightness = false; });
  }

  function increaseBrightness() {
    setBrightness(brightness + stepSize);
  }

  function decreaseBrightness() {
    setBrightness(brightness - stepSize);
  }

  // Get appropriate icon based on brightness level
  function getIcon(): string {
    if (brightness < 0.01) return "󰛩";  // sun off
    if (brightness <= 0.5) return "󰃞";   // low brightness
    return "󰃠";  // high brightness
  }

  // Get brightness as percentage string
  function getPercent(): string {
    return Math.round(brightness * 100) + "%";
  }
}
