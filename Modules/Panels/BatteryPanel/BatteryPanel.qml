import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Services.Hardware
import qs.Services.Networking
import qs.Services.Power

/*
 * BatteryPanel - Popup panel with detailed battery information
 * Shows: Battery percentage, time remaining, health, power rate, Bluetooth devices
 */
PanelPopup {
  id: root

  property real panelWidth: 280
  panelContentItem: panelContent

  // Battery data
  readonly property var battery: UPower.displayDevice
  readonly property bool isReady: battery && battery.ready && battery.percentage !== undefined
  readonly property real percent: isReady ? Math.round(battery.percentage * 100) : 0
  readonly property bool charging: isReady ? battery.state === UPowerDeviceState.Charging : false

  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

      // Header with battery icon and percentage
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Style.radiusM
        color: Color.mPrimary

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          Text {
            text: BatteryService.getIcon(root.percent, root.charging, root.isReady)
            color: Color.mOnPrimary
            font.family: Style.fontFamily
            font.pixelSize: 32
          }

          Column {
            Layout.fillWidth: true
            spacing: -2

            Text {
              text: root.isReady ? root.percent + "%" : "—"
              color: Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXXL
              font.weight: Style.fontWeightBold
            }

            Text {
              text: root.charging ? "Charging" : "Discharging"
              color: Qt.alpha(Color.mOnPrimary, 0.8)
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
            }
          }
        }
      }

      // Battery details card
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: detailsColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS
        visible: root.isReady

        ColumnLayout {
          id: detailsColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Time remaining/to full
          MetricRow {
            icon: "󰥔"
            label: root.charging ? "Time to full" : "Time remaining"
            value: {
              if (root.charging && root.battery.timeToFull > 0) {
                return Time.formatVagueHumanReadableDuration(root.battery.timeToFull);
              }
              if (!root.charging && root.battery.timeToEmpty > 0) {
                return Time.formatVagueHumanReadableDuration(root.battery.timeToEmpty);
              }
              return "N/A";
            }
            valueColor: Color.mOnSurface
          }

          // Power rate
          MetricRow {
            icon: "󱐋"
            label: "Power"
            value: root.battery.changeRate && root.battery.changeRate !== 0 ? Math.abs(root.battery.changeRate).toFixed(1) + " W" : "N/A"
            valueColor: Color.mOnSurface
          }

          // Health
          MetricRow {
            icon: "󰛨"
            label: "Health"
            value: root.battery.healthPercentage && root.battery.healthPercentage > 0 ? Math.round(root.battery.healthPercentage) + "%" : "N/A"
            valueColor: Color.mOnSurface
          }
        }
      }

      // Bluetooth devices card
      Loader {
        id: btDevicesLoader
        Layout.fillWidth: true
        Layout.preferredHeight: item ? item.implicitHeight : 0
        active: root.visible && BluetoothService.allDevicesWithBattery && BluetoothService.allDevicesWithBattery.length > 0
        visible: active

        sourceComponent: Component {
          Rectangle {
            width: btDevicesLoader.width
            implicitHeight: btColumn.implicitHeight + Style.marginM * 2
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
              id: btColumn
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginS

              // Header
              RowLayout {
                Layout.fillWidth: true

                Text {
                  text: "󰂯"
                  color: Color.mPrimary
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeL
                }

                Text {
                  text: "Bluetooth Devices"
                  color: Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeS
                  font.weight: Style.fontWeightSemiBold
                  Layout.fillWidth: true
                }
              }

              // Device list
              Repeater {
                model: BluetoothService.allDevicesWithBattery || []

                RowLayout {
                  Layout.fillWidth: true

                  Text {
                    text: BluetoothService.getBattery(modelData)
                    color: Color.mOnSurfaceVariant
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeS
                    Layout.fillWidth: true
                  }
                }
              }
            }
          }
        }
      }

      // Power Profile section
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: profileColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS
        visible: PowerProfileService.available

        ColumnLayout {
          id: profileColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Section header
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Text {
              text: PowerProfileService.getIcon()
              color: Color.mPrimary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeL
            }

            Text {
              text: "Power Profile"
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
              font.weight: Style.fontWeightMedium
              Layout.fillWidth: true
            }
          }

          // Profile buttons
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            // Power Saver button
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 36
              radius: Style.radiusS
              color: PowerProfileService.profile === 2 ? Color.mPrimary : (saverMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.2) : "transparent")
              border.color: PowerProfileService.profile === 2 ? Color.mPrimary : Color.mOutline
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: -2

                Text {
                  text: "󰌪"
                  color: PowerProfileService.profile === 2 ? Color.mOnPrimary : Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeL
                  Layout.alignment: Qt.AlignHCenter
                }

                Text {
                  text: "Saver"
                  color: PowerProfileService.profile === 2 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                  font.family: Style.fontFamily
                  font.pixelSize: 8
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              MouseArea {
                id: saverMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfileService.setProfile(2)  // PowerSaver
              }
            }

            // Balanced button
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 36
              radius: Style.radiusS
              color: PowerProfileService.profile === 1 ? Color.mPrimary : (balancedMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.2) : "transparent")
              border.color: PowerProfileService.profile === 1 ? Color.mPrimary : Color.mOutline
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: -2

                Text {
                  text: "󰛲"
                  color: PowerProfileService.profile === 1 ? Color.mOnPrimary : Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeL
                  Layout.alignment: Qt.AlignHCenter
                }

                Text {
                  text: "Balanced"
                  color: PowerProfileService.profile === 1 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                  font.family: Style.fontFamily
                  font.pixelSize: 8
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              MouseArea {
                id: balancedMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfileService.setProfile(1)  // Balanced
              }
            }

            // Performance button
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 36
              radius: Style.radiusS
              color: PowerProfileService.profile === 0 ? Color.mPrimary : (perfMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.2) : "transparent")
              border.color: PowerProfileService.profile === 0 ? Color.mPrimary : Color.mOutline
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: -2

                Text {
                  text: "󱐋"
                  color: PowerProfileService.profile === 0 ? Color.mOnPrimary : Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeL
                  Layout.alignment: Qt.AlignHCenter
                }

                Text {
                  text: "Perf"
                  color: PowerProfileService.profile === 0 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                  font.family: Style.fontFamily
                  font.pixelSize: 8
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              MouseArea {
                id: perfMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfileService.setProfile(0)  // Performance
              }
            }
          }
        }
      }

      // Open battop button
      PanelActionButton {
        Layout.fillWidth: true
        icon: "󰄛"
        label: "Open Battery Monitor"
        accentColor: Color.mPrimary
        onClicked: {
          root.close();
          battopProcess.running = true;
        }
      }
  }

  // Process to open battop
  Process {
    id: battopProcess
    command: [Settings.oNIgiRIBinDir + "niri-launch-or-focus-tui", "--floating", "--center", "--name", "Battop", "battop"]
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
