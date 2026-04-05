import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Panels.VpnPanel

/*
 * Niruv VPN Widget - Shows VPN connection status
 * Icon color changes when a VPN tunnel is active
 */
Item {
  id: root

  property ShellScreen screen: null
  property VpnPanel vpnPanel: null

  // --- VPN State ---
  property string vpnState: "disconnected"
  property string vpnName: ""

  // Computed properties
  readonly property bool isConnected: vpnState === "connected"
  readonly property string displayText: isConnected ? vpnName : "No VPN"

  // Icon based on state
  readonly property string vpnIconText: isConnected ? "󱠾" : "󱠽"

  // --- Dimensions ---
  implicitWidth: vpnRow.width
  implicitHeight: Style.barHeight

  // --- VPN Status Polling ---
  Timer {
    id: pollTimer
    interval: 5000  // Poll every 5 seconds
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: vpnStatusProcess.running = true
  }

  // Get VPN status using nmcli
  Process {
    id: vpnStatusProcess
    command: ["sh", "-c", "nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null | grep -i 'vpn\\|wireguard\\|tun' | grep -i activated | head -1"]

    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim();
        if (line.length > 0) {
          // Format: NAME:TYPE:STATE (e.g., "MyVPN:vpn:activated")
          const parts = line.split(":");
          if (parts.length >= 1) {
            root.vpnName = parts[0];
          }
          root.vpnState = "connected";
        } else {
          root.vpnState = "disconnected";
          root.vpnName = "";
        }
      }
    }
  }

  // --- UI ---

  // Background Pill
  Rectangle {
    anchors.verticalCenter: vpnRow.verticalCenter
    anchors.left: vpnRow.left
    anchors.right: vpnRow.right
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
    id: vpnRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.marginXS
    layoutDirection: Qt.RightToLeft  // Icon stays right, text expands left

    // VPN icon (first due to RightToLeft layout)
    Text {
      id: vpnIcon
      anchors.verticalCenter: parent.verticalCenter
      text: root.vpnIconText
      color: {
        if (mouseArea.containsMouse) return Color.mOnPrimary;
        if (root.isConnected) return Color.mPrimary;
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
          if (root.isConnected) return Color.mPrimary;
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
      if (now < root.toggleCooldownUntil) return;
      root.toggleCooldownUntil = now + 220;

      if (vpnPanel) {
        if (vpnPanel.toggleFromBar) {
          vpnPanel.toggleFromBar();
        } else {
          vpnPanel.toggle();
        }
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
