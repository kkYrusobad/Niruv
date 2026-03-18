import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Panels.NetworkPanel

/*
 * Niruv Bluetooth Widget - Shows bluetooth status, click to open NetworkPanel
 */
Item {
  id: root

  property ShellScreen screen: null

  // Shared network panel (can be opened by both WiFi and Bluetooth widgets)
  property NetworkPanel networkPanel: null

  // --- Bluetooth State ---
  // States: "connected", "on", "off"
  property string btState: "on"
  property string connectedDevice: ""

  // Computed properties
  readonly property bool isConnected: btState === "connected" && connectedDevice !== ""
  readonly property bool isOff: btState === "off"
  readonly property string displayText: {
    if (isOff) return "Link Down";
    if (isConnected) return connectedDevice;
    return "Disconnected";
  }

  // Icon based on state
  readonly property string btIconText: {
    if (isOff) return "󰂲";           // bluetooth-off
    if (isConnected) return "";     // bluetooth-connected
    return "";                       // bluetooth on but not connected
  }

  // --- Dimensions ---
  implicitWidth: btRow.width
  implicitHeight: Style.barHeight

  // --- Bluetooth Status Polling ---
  Timer {
    id: pollTimer
    interval: 5000  // Poll every 5 seconds
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: btStatusProcess.running = true
  }

  // Get Bluetooth status using bluetoothctl
  Process {
    id: btStatusProcess
    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'; bluetoothctl devices Connected 2>/dev/null | head -1"]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const powerState = lines[0];  // First line is power state

        if (powerState === "off") {
          root.btState = "off";
          root.connectedDevice = "";
        } else {
          // Check for connected device (second line, format: "Device XX:XX:XX:XX:XX:XX DeviceName")
          if (lines.length > 1 && lines[1] && lines[1].startsWith("Device ")) {
            // Extract device name (everything after the MAC address)
            const parts = lines[1].split(" ");
            if (parts.length >= 3) {
              root.connectedDevice = parts.slice(2).join(" ");
              root.btState = "connected";
            } else {
              root.btState = "on";
              root.connectedDevice = "";
            }
          } else {
            root.btState = "on";
            root.connectedDevice = "";
          }
        }
      }
    }
  }

  // --- Process to open bluetui ---
  Process {
    id: btProcess
    command: ["sh", "-c", "rfkill unblock bluetooth; " + Settings.oNIgiRIBinDir + "niri-launch-or-focus-tui --floating --center --name Bluetooth bluetui"]
  }

  // --- UI ---

  // Background Pill
  Rectangle {
    anchors.verticalCenter: btRow.verticalCenter
    anchors.left: btRow.left
    anchors.right: btRow.right
    anchors.margins: -Style.marginS
    height: 18
    color: mouseArea.containsMouse ? Color.mBlue : Color.transparent
    radius: height / 2

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  Row {
    id: btRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.marginXS
    layoutDirection: Qt.RightToLeft  // Icon stays right, text expands left

    // Bluetooth icon (first due to RightToLeft layout)
    Text {
      id: btIcon
      anchors.verticalCenter: parent.verticalCenter
      text: root.btIconText
      color: {
        if (mouseArea.containsMouse) return Color.mOnPrimary;
        if (root.isOff) return Color.mOnSurface;
        return Color.mOnSurface;
      }
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
      font.weight: Font.Normal

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.InOutCubic
        }
      }
    }

    // Status text container (expands to the left)
    Item {
      id: statusContainer
      height: parent.height
      width: isExpanded ? statusText.implicitWidth + Style.marginXS : 0
      clip: true

      Behavior on width {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Text {
        id: statusText
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        text: root.displayText
        color: {
          if (mouseArea.containsMouse) return Color.mOnPrimary;
          if (root.isOff) return Color.mOutline;
          return Color.mOnSurface;
        }
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeM
        font.weight: Style.fontWeightMedium

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.InOutCubic
          }
        }
      }
    }
  }

  // --- Interaction ---
  property bool isExpanded: false
  property double toggleCooldownUntil: 0

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: expandTimer.start()
    onExited: {
      expandTimer.stop()
      isExpanded = false
    }

    onClicked: {
      const now = Date.now();
      if (now < root.toggleCooldownUntil) {
        return;
      }
      root.toggleCooldownUntil = now + 220;

      if (networkPanel) {
        if (networkPanel.toggleFromBar) {
          networkPanel.toggleFromBar();
        } else {
          networkPanel.toggle();
        }
      } else {
        // Fallback: open bluetui directly
        btProcess.running = true;
      }
    }
  }

  // Delay before expanding
  Timer {
    id: expandTimer
    interval: 500  // 500ms delay
    repeat: false
    onTriggered: isExpanded = true
  }
}
