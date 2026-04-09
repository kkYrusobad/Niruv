import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * VpnPanel - minimal ProtonVPN popup panel
 * Provides a single action: protonvpn connect
 */
PanelPopup {
    id: root

    property real panelWidth: 280
    property double lastToggleAtMs: 0
    property int toggleDebounceMs: 260
    property bool isBusy: false

    panelContentItem: panelContent

    function toggleFromBar() {
        const now = Date.now();
        if ((now - root.lastToggleAtMs) < root.toggleDebounceMs) {
            return;
        }
        root.lastToggleAtMs = now;
        root.toggle();
    }

    Process {
        id: connectProcess
        command: ["protonvpn", "connect"]
        onExited: {
            root.isBusy = false;
        }
    }

    function connectVpn() {
        if (root.isBusy) {
            return;
        }
        root.isBusy = true;
        connectProcess.running = true;
    }

    PanelSurface {
        id: panelContent
        width: root.panelWidth
        height: implicitHeight

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginXS

                Text {
                    text: "ProtonVPN"
                    color: Color.mOnSurface
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeM
                    font.weight: Style.fontWeightBold
                }

                Text {
                    text: root.isBusy ? "Running protonvpn connect..." : "Press connect to run protonvpn connect"
                    color: Color.mOnSurfaceVariant
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeXS
                    elide: Text.ElideRight
                }
            }
        }

        PanelActionButton {
            Layout.fillWidth: true
            compact: true
            icon: ""
            label: root.isBusy ? "Connecting..." : "Connect"
            accentColor: Color.mPrimary
            baseColor: "transparent"
            onClicked: {
                if (!root.isBusy) {
                    root.connectVpn();
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
}
