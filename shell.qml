/*
 * Niruv – A minimal Gruvbox-themed desktop shell for Niri
 * Built on Quickshell (Qt/QML)
 * Licensed under the MIT License.
 */

// Qt & Quickshell Core
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io


// Commons
import qs.Commons

// Services
import qs.Services.System
import qs.Services.UI

// Modules
import qs.Modules.Bar
import qs.Modules.Launcher
import qs.Modules.OSD
import qs.Modules.Notification

ShellRoot {
  id: shellRoot

  // Global launcher reference for accessibility
  property alias launcher: launcher

  Component.onCompleted: {
    Logger.i("Shell", "---------------------------");
    Logger.i("Shell", "Niruv Shell Hello!");
    Logger.i("Shell", "---------------------------");
  }


  // Reload handling
  Connections {
    target: Quickshell
    function onReloadCompleted() {
      Quickshell.inhibitReloadPopup();
    }
    function onReloadFailed() {
      if (Settings?.isDebug) {
        // Only show popup in debug mode
      } else {
        Quickshell.inhibitReloadPopup();
      }
    }
  }

  // Create a bar on each screen
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property ShellScreen modelData

      screen: modelData

      // Layer shell anchors based on position
      anchors {
        top: Settings.data.bar.position !== "bottom"
        bottom: Settings.data.bar.position !== "top"
        left: Settings.data.bar.position !== "right"
        right: Settings.data.bar.position !== "left"
      }

      // Bar dimensions
      implicitHeight: (Settings.data.bar.position === "top" || Settings.data.bar.position === "bottom") ? Style.barHeight : 0
      implicitWidth: (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? Style.barHeight : 0

      // Layer shell properties
      WlrLayershell.namespace: "niruv-bar"
      WlrLayershell.layer: WlrLayer.Top
      exclusiveZone: (Settings.data.bar.position === "top" || Settings.data.bar.position === "bottom") ? implicitHeight : implicitWidth

      // Transparent background (we draw our own)
      color: "transparent"

      // Bar content
      Bar {
        anchors.fill: parent
        screen: barWindow.modelData
      }
    }
  }

  // Panel backdrop overlay (transparent, click-outside-to-close)
  // Appears on each screen when a popup panel is open
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panelBackdrop
      required property ShellScreen modelData

      screen: modelData

      // Cover the entire screen (except bar)
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // Exclude the bar region so bar icon clicks don't race with backdrop close logic.
      margins {
        top: Settings.data.bar.position === "top" ? Style.barHeight : 0
        bottom: Settings.data.bar.position === "bottom" ? Style.barHeight : 0
        left: Settings.data.bar.position === "left" ? Style.barHeight : 0
        right: Settings.data.bar.position === "right" ? Style.barHeight : 0
      }

      // Layer shell properties - sits between bar and popups
      WlrLayershell.namespace: "niruv-panel-backdrop"
      WlrLayershell.layer: WlrLayer.Top
      // No exclusive zone - doesn't reserve space

      // Fully transparent - just catches clicks
      color: "transparent"
      
      // Only visible when a panel is open
      visible: PanelState.hasOpenPanel

      // Catch clicks anywhere on this overlay to close panels
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: true
        onPressed: function(mouse) {
          mouse.accepted = true;
          PanelState.closeOpenPanel();
        }
      }
    }
  }

  // Launcher overlay (on primary screen)
  PanelWindow {
    id: launcherWindow

    screen: Quickshell.screens[0] || null

    // Cover the entire screen
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Layer shell properties
    WlrLayershell.namespace: "niruv-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcher.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Semi-transparent backdrop
    color: launcher.isOpen ? "#80000000" : "transparent"
    visible: launcher.isOpen

    Behavior on color {
      ColorAnimation { duration: Style.animationFast }
    }

    // Launcher component
    Launcher {
      id: launcher
      anchors.fill: parent
    }
  }

  // OSD overlay for volume, brightness, and media track changes
  OSD {}

  // Notification overlay
  Notification {}

  // IPC Service for external triggers
  IPCService {}
}


