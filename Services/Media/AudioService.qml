pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons

/*
 * AudioService - PipeWire audio control singleton
 * Provides volume control, mute toggle, and device access
 */
Singleton {
  id: root

  // Signals for OSD (using 'Updated' to avoid conflict with property change signals)
  signal volumeUpdated()
  signal mutedUpdated()

  // Current output device (sink)
  readonly property PwNode sink: Pipewire.ready ? Pipewire.defaultAudioSink : null

  // Output Volume (0.0 - 1.0)
  readonly property real volume: {
    if (!sink?.audio) return 0;
    const vol = sink.audio.volume;
    if (vol === undefined || isNaN(vol)) return 0;
    return Math.max(0, Math.min(1.0, vol));
  }

  // Emit signal when volume changes
  onVolumeChanged: {
    if (!isSettingVolume) {
      volumeUpdated();
    }
  }

  // Muted state
  readonly property bool muted: sink?.audio?.muted ?? true

  // Emit signal when muted changes
  onMutedChanged: mutedUpdated()

  // Volume step for increase/decrease (5%)
  readonly property real stepVolume: 0.05

  // Epsilon for float comparison
  readonly property real epsilon: 0.005

  // Internal state for feedback loop prevention
  property bool isSettingVolume: false

  // List of available audio output devices (sinks)
  readonly property var sinks: {
    if (!Pipewire.ready) return [];
    let devices = [];
    let nodes = Pipewire.nodes.values;
    for (let i = 0; i < nodes.length; i++) {
      let node = nodes[i];
      if (node && !node.isStream && node.isSink) {
        devices.push(node);
      }
    }
    return devices;
  }

  // Bind sink to ensure properties are available
  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  // Track all sinks to ensure their properties are available
  PwObjectTracker {
    objects: root.sinks
  }

  // Device switching function
  function setAudioSink(newSink) {
    if (!Pipewire.ready) {
      Logger.w("AudioService", "Pipewire not ready");
      return;
    }
    if (!newSink) {
      Logger.w("AudioService", "Invalid sink");
      return;
    }
    Logger.d("AudioService", "Switching to sink: " + newSink.description);
    Pipewire.preferredDefaultAudioSink = newSink;
  }

  // Volume control functions
  function increaseVolume() {
    if (!Pipewire.ready || !sink?.audio) return;
    if (volume >= 1.0) return;
    setVolume(Math.min(1.0, volume + stepVolume));
  }

  function decreaseVolume() {
    if (!Pipewire.ready || !sink?.audio) return;
    if (volume <= 0) return;
    setVolume(Math.max(0, volume - stepVolume));
  }

  function setVolume(newVolume: real) {
    if (!Pipewire.ready || !sink?.ready || !sink?.audio) {
      Logger.w("AudioService", "No sink available or not ready");
      return;
    }

    const clampedVolume = Math.max(0, Math.min(1.0, newVolume));
    const delta = Math.abs(clampedVolume - sink.audio.volume);
    if (delta < root.epsilon) return;

    // Set flag to prevent feedback loop
    isSettingVolume = true;
    sink.audio.muted = false;
    sink.audio.volume = clampedVolume;

    // Clear flag after a short delay
    Qt.callLater(() => { isSettingVolume = false; });
  }

  function setMuted(muted: bool) {
    if (!Pipewire.ready || !sink?.audio) {
      Logger.w("AudioService", "No sink available or Pipewire not ready");
      return;
    }
    sink.audio.muted = muted;
  }

  function toggleMute() {
    setMuted(!muted);
  }

  // Get appropriate icon based on volume/mute state
  function getIcon(): string {
    if (muted) return "";  // muted icon

    if (volume < root.epsilon) return "";  // effectively 0
    if (volume <= 0.33) return "";  // low
    if (volume <= 0.66) return "";  // medium
    return "";  // high
  }

  // Get volume as percentage string
  function getPercent(): string {
    return Math.round(volume * 100) + "%";
  }
}
