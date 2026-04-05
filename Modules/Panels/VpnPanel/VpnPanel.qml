import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * VpnPanel - ProtonVPN popup panel
 * Shows: connection status, country quick-connect grid, disconnect
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

  // === VPN State ===
  property string vpnState: "disconnected"  // "connected", "disconnected"
  property string vpnName: ""
  property string vpnCountryCode: ""
  property bool isBusy: false  // true while connect/disconnect in progress
  readonly property bool isConnected: vpnState === "connected"
  property string lastRefreshLabel: "--:--"

  // Free-tier countries
  readonly property var countries: [
    { code: "CA", name: "Canada",      flag: "🇨🇦" },
    { code: "CH", name: "Switzerland",  flag: "🇨🇭" },
    { code: "JP", name: "Japan",       flag: "🇯🇵" },
    { code: "MX", name: "Mexico",      flag: "🇲🇽" },
    { code: "NL", name: "Netherlands", flag: "🇳🇱" },
    { code: "NO", name: "Norway",      flag: "🇳🇴" },
    { code: "PL", name: "Poland",      flag: "🇵🇱" },
    { code: "RO", name: "Romania",     flag: "🇷🇴" },
    { code: "SG", name: "Singapore",   flag: "🇸🇬" },
    { code: "US", name: "United States", flag: "🇺🇸" }
  ]

  function refreshStatus() {
    vpnStatusProcess.running = true;
    const now = new Date();
    lastRefreshLabel = now.toLocaleTimeString(Qt.locale(), "hh:mm:ss");
  }

  // === VPN Status Check (nmcli) ===
  Process {
    id: vpnStatusProcess
    command: ["sh", "-c", "nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null | grep -i 'vpn\\|wireguard\\|tun' | grep -i activated | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim();
        if (line.length > 0) {
          const parts = line.split(":");
          root.vpnName = parts.length >= 1 ? parts[0] : "VPN";
          root.vpnState = "connected";
          // Try to extract country code from connection name (ProtonVPN names contain country codes)
          root.vpnCountryCode = root.extractCountryCode(root.vpnName);
        } else {
          root.vpnState = "disconnected";
          root.vpnName = "";
          root.vpnCountryCode = "";
        }
      }
    }
  }

  // Extract 2-letter country code from ProtonVPN connection name
  function extractCountryCode(name) {
    const upper = name.toUpperCase();
    for (let i = 0; i < countries.length; i++) {
      if (upper.indexOf(countries[i].code) !== -1) {
        return countries[i].code;
      }
    }
    return "";
  }

  // === Connect / Disconnect Processes ===
  Process {
    id: connectProcess
    property string targetCountry: ""
    command: ["protonvpn", "connect", "--country", targetCountry]
    onExited: {
      root.isBusy = false;
      root.refreshStatus();
    }
  }

  Process {
    id: disconnectProcess
    command: ["protonvpn", "disconnect"]
    onExited: {
      root.isBusy = false;
      root.refreshStatus();
    }
  }

  function connectToCountry(code) {
    if (isBusy) return;
    isBusy = true;
    connectProcess.targetCountry = code;
    connectProcess.running = true;
  }

  function disconnectVpn() {
    if (isBusy) return;
    isBusy = true;
    disconnectProcess.running = true;
  }

  // === Panel Content ===
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

    // --- Status Summary ---
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

        // Status icon
        Rectangle {
          Layout.preferredWidth: 34
          Layout.preferredHeight: 34
          radius: 17
          color: root.isConnected ? Color.mPrimary : Color.mOutline

          Text {
            anchors.centerIn: parent
            text: root.isConnected ? "󰌆" : "󰌊"
            color: root.isConnected ? Color.mOnPrimary : Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: 16
          }
        }

        // Status text
        Column {
          Layout.fillWidth: true
          spacing: 1

          Text {
            text: {
              if (root.isBusy) return "Working...";
              return root.isConnected ? "VPN Connected" : "VPN Disconnected";
            }
            color: Color.mOnSurface
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeM
            font.weight: Style.fontWeightBold
          }

          Text {
            text: root.isConnected ? root.vpnName : "Updated " + root.lastRefreshLabel
            color: Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeXS
            elide: Text.ElideRight
            width: parent.width
          }
        }

        // Refresh button
        Rectangle {
          Layout.preferredWidth: 34
          Layout.preferredHeight: 34
          radius: 17
          color: refreshMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.25) : Qt.alpha(Color.mPrimary, 0.12)
          border.color: Qt.alpha(Color.mPrimary, 0.4)
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰑐"
            color: Color.mPrimary
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

    // --- Connected Info (only when connected) ---
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS
      visible: root.isConnected

      PanelInfoPill {
        Layout.fillWidth: true
        label: "Server: " + (root.vpnCountryCode.length > 0 ? root.vpnCountryCode : "—")
      }

      PanelInfoPill {
        Layout.fillWidth: true
        label: "Status: Active"
      }
    }

    // --- Country Grid ---
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: countryGrid.implicitHeight + Style.marginM * 2
      radius: Style.radiusM
      color: Color.mSurfaceVariant
      border.color: Color.mOutline
      border.width: Style.borderS

      ColumnLayout {
        id: countryGrid
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        // Section header
        Text {
          text: "Quick Connect"
          color: Color.mOnSurface
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
        }

        // Country buttons in 2-column grid
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: Style.marginXS
          columnSpacing: Style.marginXS

          Repeater {
            model: root.countries

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 32
              radius: Style.radiusS
              border.color: isActive ? Color.mPrimary : Color.mOutline
              border.width: isActive ? 2 : Style.borderS

              readonly property bool isActive: root.isConnected && root.vpnCountryCode === modelData.code
              readonly property bool isHovered: countryMouse.containsMouse

              color: {
                if (isActive) return Qt.alpha(Color.mPrimary, 0.2);
                if (isHovered) return Qt.alpha(Color.mPrimary, 0.1);
                return Color.mSurface;
              }

              scale: countryMouse.pressed ? 0.97 : 1.0
              opacity: root.isBusy && !isActive ? 0.5 : 1.0

              Behavior on color {
                ColorAnimation { duration: Style.animationFast; easing.type: Style.easingStandard }
              }

              Behavior on scale {
                NumberAnimation { duration: Style.animationFaster; easing.type: Style.easingEnter }
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginXS

                Text {
                  text: modelData.flag
                  font.pixelSize: Style.fontSizeM
                }

                Text {
                  Layout.fillWidth: true
                  text: modelData.code
                  color: isActive ? Color.mPrimary : Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeS
                  font.weight: isActive ? Style.fontWeightBold : Style.fontWeightMedium
                }

                // Active indicator
                Text {
                  visible: isActive
                  text: "󰄬"
                  color: Color.mPrimary
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeS
                }
              }

              MouseArea {
                id: countryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.isBusy ? Qt.BusyCursor : Qt.PointingHandCursor
                onClicked: {
                  if (!root.isBusy) {
                    root.connectToCountry(modelData.code);
                  }
                }
              }
            }
          }
        }
      }
    }

    // --- Disconnect Button (only when connected) ---
    PanelActionButton {
      Layout.fillWidth: true
      visible: root.isConnected && !root.isBusy
      compact: true
      icon: "󰈂"
      label: "Disconnect"
      accentColor: Color.mError
      baseColor: "transparent"
      onClicked: root.disconnectVpn()
    }

    // --- Busy indicator ---
    Text {
      Layout.fillWidth: true
      visible: root.isBusy
      text: "⏳ Connecting..."
      color: Color.mOnSurfaceVariant
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeXS
      horizontalAlignment: Text.AlignHCenter
    }
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
