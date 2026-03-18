import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Panels.NetworkPanel

/*
 * Niruv WiFi Widget - Shows network status, click to open NetworkPanel
 */
Item {
  id: root

  property ShellScreen screen: null

  // Shared network panel (can be opened by both WiFi and Bluetooth widgets)
  property NetworkPanel networkPanel: null

  // --- WiFi State ---
  // States: "connected", "disconnected", "off"
  property string wifiState: "disconnected"
  property string ssid: ""

  // Computed properties
  readonly property bool isConnected: wifiState === "connected" && ssid !== ""
  readonly property bool isOff: wifiState === "off"
  readonly property string displayText: {
    if (isOff) return "Off";
    if (isConnected) return ssid;
    return "Disconnected";
  }

  // Icon based on state
  readonly property string wifiIconText: {
    if (isOff) return "󰤭";           // wifi-off
    if (isConnected) return "󰤨";     // wifi connected
    return "󰤭";                       // wifi disconnected (same as off visually)
  }

  // --- Dimensions ---
  implicitWidth: wifiRow.width
  implicitHeight: Style.barHeight

  // --- Network Status Polling ---
  Timer {
    id: pollTimer
    interval: 5000  // Poll every 5 seconds
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: wifiStatusProcess.running = true
  }

  // Get WiFi status using nmcli
  Process {
    id: wifiStatusProcess
    command: ["sh", "-c", "nmcli -t -f SSID,ACTIVE device wifi list 2>/dev/null | grep ':yes$' | head -1; nmcli radio wifi"]

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const radioState = lines[lines.length - 1];  // Last line is radio state

        if (radioState === "disabled") {
          root.wifiState = "off";
          root.ssid = "";
        } else {
          // Look for connected network (line with :yes at end)
          let connected = false;
          for (let i = 0; i < lines.length - 1; i++) {
            const line = lines[i];
            if (line && line.endsWith(":yes")) {
              // Format: SSID:ACTIVE (e.g., "MyNetwork:yes")
              // SSID can contain colons, so remove only the last ":yes"
              const ssidPart = line.slice(0, -4);  // Remove ":yes"
              root.ssid = ssidPart;
              root.wifiState = "connected";
              connected = true;
              break;
            }
          }
          if (!connected) {
            root.wifiState = "disconnected";
            root.ssid = "";
          }
        }
      }
    }
  }

  // --- Process to open impala ---
  Process {
    id: wifiProcess
    command: ["sh", "-c", "rfkill unblock wifi; " + Settings.oNIgiRIBinDir + "niri-launch-or-focus-tui --floating --center --name WiFi impala"]
  }

  // --- UI ---

  // Background Pill
  Rectangle {
    anchors.verticalCenter: wifiRow.verticalCenter
    anchors.left: wifiRow.left
    anchors.right: wifiRow.right
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
    id: wifiRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.marginXS
    layoutDirection: Qt.RightToLeft  // Icon stays right, text expands left

    // WiFi icon (first due to RightToLeft layout)
    Text {
      id: wifiIcon
      anchors.verticalCenter: parent.verticalCenter
      text: root.wifiIconText
      color: {
        if (mouseArea.containsMouse) return Color.mOnPrimary;
        if (root.isOff) return Color.mOutline;
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
        // Fallback: open impala directly
        wifiProcess.running = true;
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
