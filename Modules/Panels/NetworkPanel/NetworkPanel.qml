import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * NetworkPanel - Combined WiFi and Bluetooth popup panel
 * Shows: WiFi status + toggle, Bluetooth status + toggle, TUI launcher buttons
 */
PanelPopup {
  id: root

  property real panelWidth: 280
  property double lastToggleAtMs: 0
  property int toggleDebounceMs: 260
  panelContentItem: panelContent

  function toggleFromBar() {
    const now = Date.now();
    if ((now - root.lastToggleAtMs) < root.toggleDebounceMs) {
      return;
    }
    root.lastToggleAtMs = now;
    root.toggle();
  }

  onIsOpenChanged: {
    if (isOpen) {
      refreshStatus();
    }
  }

  // === WiFi State ===
  property string wifiState: "disconnected"  // "connected", "disconnected", "off"
  property string wifiSsid: ""
  readonly property bool wifiConnected: wifiState === "connected" && wifiSsid !== ""
  readonly property bool wifiOff: wifiState === "off"

  // === Bluetooth State ===
  property string btState: "on"  // "connected", "on", "off"
  property string btDevice: ""
  readonly property bool btConnected: btState === "connected" && btDevice !== ""
  readonly property bool btOff: btState === "off"
  readonly property bool anyConnected: wifiConnected || btConnected
  readonly property bool allRadiosOff: wifiOff && btOff
  property string lastRefreshLabel: "--:--"

  function refreshStatus() {
    wifiStatusProcess.running = true;
    btStatusProcess.running = true;

    const now = new Date();
    lastRefreshLabel = now.toLocaleTimeString(Qt.locale(), "hh:mm:ss");
  }

  Timer {
    interval: 10000
    running: root.visible
    repeat: true
    onTriggered: refreshStatus()
  }

  // === WiFi Status Polling ===
  Process {
    id: wifiStatusProcess
    command: ["sh", "-c", "nmcli -t -f SSID,ACTIVE device wifi list 2>/dev/null | grep ':yes$' | head -1; nmcli radio wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const radioState = lines[lines.length - 1];
        if (radioState === "disabled") {
          root.wifiState = "off";
          root.wifiSsid = "";
        } else {
          let connected = false;
          for (let i = 0; i < lines.length - 1; i++) {
            const line = lines[i];
            if (line && line.endsWith(":yes")) {
              root.wifiSsid = line.slice(0, -4);
              root.wifiState = "connected";
              connected = true;
              break;
            }
          }
          if (!connected) {
            root.wifiState = "disconnected";
            root.wifiSsid = "";
          }
        }
      }
    }
  }

  // === Bluetooth Status Polling ===
  Process {
    id: btStatusProcess
    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'; bluetoothctl devices Connected 2>/dev/null | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const powerState = lines[0];
        if (powerState === "off") {
          root.btState = "off";
          root.btDevice = "";
        } else {
          if (lines.length > 1 && lines[1] && lines[1].startsWith("Device ")) {
            const parts = lines[1].split(" ");
            if (parts.length >= 3) {
              root.btDevice = parts.slice(2).join(" ");
              root.btState = "connected";
            } else {
              root.btState = "on";
              root.btDevice = "";
            }
          } else {
            root.btState = "on";
            root.btDevice = "";
          }
        }
      }
    }
  }

  // === Toggle Processes ===
  Process {
    id: wifiToggleProcess
    property bool targetState: true
    command: ["nmcli", "radio", "wifi", targetState ? "on" : "off"]
    onExited: wifiStatusProcess.running = true
  }

  Process {
    id: btToggleProcess
    property bool targetState: true
    command: ["bluetoothctl", "power", targetState ? "on" : "off"]
    onExited: btStatusProcess.running = true
  }

  // === TUI Launch Processes ===
  Process {
    id: wifiTuiProcess
    command: ["sh", "-c", "rfkill unblock wifi; " + Settings.oNIgiRIBinDir + "niri-launch-or-focus-tui --floating --center --name WiFi impala"]
  }

  Process {
    id: btTuiProcess
    command: ["sh", "-c", "rfkill unblock bluetooth; " + Settings.oNIgiRIBinDir + "niri-launch-or-focus-tui --floating --center --name Bluetooth bluetui"]
  }

  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

      // Summary
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 72
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: root.anyConnected ? Color.mBlue : Color.mOutline

            Text {
              anchors.centerIn: parent
              text: root.anyConnected ? "󰤨" : "󰤭"
              color: root.anyConnected ? Color.mOnPrimary : Color.mOnSurfaceVariant
              font.family: Style.fontFamily
              font.pixelSize: 16
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: root.allRadiosOff ? "Wireless Disabled" : (root.anyConnected ? "Network Connected" : "No Active Connection")
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
            }

            Text {
              text: "Updated " + root.lastRefreshLabel
              color: Color.mOnSurfaceVariant
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXS
            }
          }

          Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: refreshMouse.containsMouse ? Qt.alpha(Color.mBlue, 0.25) : Qt.alpha(Color.mBlue, 0.12)
            border.color: Qt.alpha(Color.mBlue, 0.4)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "󰑐"
              color: Color.mBlue
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
            }

            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refreshStatus()
            }
          }
        }
      }

      // === WiFi Section ===
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: wifiColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        ColumnLayout {
          id: wifiColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // WiFi header row
          RowLayout {
            Layout.fillWidth: true

            Text {
              text: root.wifiOff ? "󰤭" : (root.wifiConnected ? "󰤨" : "󰤭")
              color: root.wifiOff ? Color.mOnSurfaceVariant : Color.mBlue
              font.family: Style.fontFamily
              font.pixelSize: 18
            }

            Column {
              Layout.fillWidth: true
              spacing: -2

              Text {
                text: "WiFi"
                color: Color.mOnSurface
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
              }

              Text {
                text: {
                  if (root.wifiOff) return "Radio is off";
                  if (root.wifiConnected) return root.wifiSsid;
                  return "Not connected";
                }
                color: Color.mOnSurfaceVariant
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
              }
            }

            PanelStatusChip {
              label: root.wifiOff ? "OFF" : (root.wifiConnected ? "CONNECTED" : "IDLE")
              backgroundColor: root.wifiOff ? Color.mOutline : (root.wifiConnected ? Color.mBlue : Qt.alpha(Color.mBlue, 0.25))
              foregroundColor: root.wifiOff ? Color.mOnSurfaceVariant : (root.wifiConnected ? Color.mOnPrimary : Color.mBlue)
            }

            // Toggle button
            Rectangle {
              Layout.preferredWidth: 44
              Layout.preferredHeight: 24
              radius: 12
              color: root.wifiOff ? Color.mOutline : Color.mBlue

              Rectangle {
                x: root.wifiOff ? 2 : parent.width - width - 2
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: Color.mSurface

                Behavior on x {
                  NumberAnimation { duration: Style.animationFast }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  wifiToggleProcess.targetState = root.wifiOff;
                  wifiToggleProcess.running = true;
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            PanelInfoPill {
              Layout.fillWidth: true
              label: "Radio: " + (root.wifiOff ? "Off" : "On")
            }

            PanelInfoPill {
              Layout.fillWidth: true
              label: root.wifiConnected ? "Link: Active" : "Link: Inactive"
            }
          }

          // Open WiFi settings button
          PanelActionButton {
            Layout.fillWidth: true
            compact: true
            icon: "󰛳"
            label: "WiFi Settings"
            accentColor: Color.mBlue
            baseColor: "transparent"
            onClicked: {
              root.close();
              wifiTuiProcess.running = true;
            }
          }
        }
      }

      // === Bluetooth Section ===
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: btColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        ColumnLayout {
          id: btColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Bluetooth header row
          RowLayout {
            Layout.fillWidth: true

            Text {
              text: root.btOff ? "" : (root.btConnected ? "󰂳" : "")
              color: root.btOff ? Color.mOnSurfaceVariant : Color.mBlue
              font.family: Style.fontFamily
              font.pixelSize: 18
            }

            Column {
              Layout.fillWidth: true
              spacing: -2

              Text {
                text: "Bluetooth"
                color: Color.mOnSurface
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
              }

              Text {
                text: {
                  if (root.btOff) return "Radio is off";
                  if (root.btConnected) return root.btDevice;
                  return "Not connected";
                }
                color: Color.mOnSurfaceVariant
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeS
              }
            }

            PanelStatusChip {
              label: root.btOff ? "OFF" : (root.btConnected ? "CONNECTED" : "IDLE")
              backgroundColor: root.btOff ? Color.mOutline : (root.btConnected ? Color.mBlue : Qt.alpha(Color.mBlue, 0.25))
              foregroundColor: root.btOff ? Color.mOnSurfaceVariant : (root.btConnected ? Color.mOnPrimary : Color.mBlue)
            }

            // Toggle button
            Rectangle {
              Layout.preferredWidth: 44
              Layout.preferredHeight: 24
              radius: 12
              color: root.btOff ? Color.mOutline : Color.mBlue

              Rectangle {
                x: root.btOff ? 2 : parent.width - width - 2
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: Color.mSurface

                Behavior on x {
                  NumberAnimation { duration: Style.animationFast }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  btToggleProcess.targetState = root.btOff;
                  btToggleProcess.running = true;
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            PanelInfoPill {
              Layout.fillWidth: true
              label: "Power: " + (root.btOff ? "Off" : "On")
            }

            PanelInfoPill {
              Layout.fillWidth: true
              label: root.btConnected ? "Device: Active" : "Device: None"
            }
          }

          // Open Bluetooth settings button
          PanelActionButton {
            Layout.fillWidth: true
            compact: true
            icon: "󰀂"
            label: "Bluetooth Settings"
            accentColor: Color.mBlue
            baseColor: "transparent"
            onClicked: {
              root.close();
              btTuiProcess.running = true;
            }
          }
        }
      }

      Text {
        Layout.fillWidth: true
        text: "Tip: Toggle radios here, open full TUI tools for scanning and pairing."
        color: Qt.alpha(Color.mOnSurfaceVariant, 0.85)
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSizeXS
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

    // Animation
    scale: root.visible ? 1.0 : 0.95
    opacity: root.visible ? 1.0 : 0.0
    transformOrigin: Item.Top

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Style.easingEnter
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Style.easingEnter
      }
    }
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
