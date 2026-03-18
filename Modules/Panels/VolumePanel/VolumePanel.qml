import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Media

/*
 * VolumePanel - Popup panel with volume controls
 * Shows: Volume slider, mute toggle, open mixer button
 */
PanelPopup {
  id: root

  property real panelWidth: 260
  panelContentItem: panelContent

  // Volume state from AudioService
  readonly property real volume: AudioService.volume
  readonly property bool muted: AudioService.muted
  readonly property int volumePercent: Math.round(volume * 100)

  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

      // Header with volume icon and percentage
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: root.muted ? Color.mSurfaceVariant : Color.mPrimary

        Behavior on color {
          ColorAnimation { duration: Style.animationFast }
        }

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          // Volume icon (clickable mute toggle)
          Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: width / 2
            color: muteIconMouseArea.containsMouse ? Qt.alpha(Color.mOnPrimary, 0.2) : "transparent"

            Text {
              anchors.centerIn: parent
              text: AudioService.getIcon()
              color: root.muted ? Color.mOnSurfaceVariant : Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: 22
            }

            MouseArea {
              id: muteIconMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: AudioService.toggleMute()
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: -2

            Text {
              text: root.muted ? "Muted" : root.volumePercent + "%"
              color: root.muted ? Color.mOnSurfaceVariant : Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
              font.weight: Style.fontWeightBold
            }

            Text {
              text: "Volume"
              color: Qt.alpha(root.muted ? Color.mOnSurfaceVariant : Color.mOnPrimary, 0.7)
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
            }
          }
        }
      }

      // Volume slider card
      SliderControl {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        value: root.volume
        accentColor: root.muted ? Color.mOnSurfaceVariant : Color.mPrimary
        iconColor: Color.mOnSurfaceVariant
        leftIcon: "󰕿"
        rightIcon: "󰕾"
        onValueChangeRequested: function(newValue) {
          AudioService.setVolume(newValue);
        }
      }

      // Open mixer button
      PanelActionButton {
        Layout.fillWidth: true
        icon: "󰕾"
        label: "Open Audio Mixer"
        accentColor: Color.mPrimary
        onClicked: {
          root.close();
          mixerProcess.running = true;
        }
      }

      // Output Devices section
      Loader {
        id: devicesLoader
        Layout.fillWidth: true
        Layout.preferredHeight: item ? item.implicitHeight : 0
        active: root.visible && AudioService.sinks && AudioService.sinks.length > 1
        visible: active

        sourceComponent: Component {
          Rectangle {
            width: devicesLoader.width
            implicitHeight: devicesColumn.implicitHeight + Style.marginM * 2
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
              id: devicesColumn
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginS

              // Section header
              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Text {
                  text: "󰓃"
                  color: Color.mPrimary
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeL
                }

                Text {
                  text: "Output Device"
                  color: Color.mOnSurface
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeS
                  font.weight: Style.fontWeightMedium
                  Layout.fillWidth: true
                }
              }

              // Device list
              Repeater {
                model: AudioService.sinks

                Rectangle {
                  required property var modelData
                  required property int index

                  Layout.fillWidth: true
                  Layout.preferredHeight: 32
                  radius: Style.radiusS
                  color: deviceMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.15) : "transparent"

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.marginS
                    anchors.rightMargin: Style.marginS
                    spacing: Style.marginS

                    // Radio indicator
                    Rectangle {
                      Layout.preferredWidth: 16
                      Layout.preferredHeight: 16
                      radius: 8
                      color: "transparent"
                      border.color: AudioService.sink?.id === modelData.id ? Color.mPrimary : Color.mOnSurfaceVariant
                      border.width: 2

                      Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: Color.mPrimary
                        visible: AudioService.sink?.id === modelData.id
                      }
                    }

                    // Device name
                    Text {
                      text: modelData.description || modelData.name || "Unknown Device"
                      color: Color.mOnSurface
                      font.family: Style.fontFamily
                      font.pixelSize: Style.fontSizeS
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }

                  MouseArea {
                    id: deviceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      AudioService.setAudioSink(modelData);
                    }
                  }
                }
              }
            }
          }
        }
      }
  }

  // Process to open mixer
  Process {
    id: mixerProcess
    command: ["sh", "-c", "pwvucontrol || pavucontrol || alsamixer"]
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
