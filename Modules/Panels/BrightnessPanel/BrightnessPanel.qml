import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Hardware
import qs.Services.System

/*
 * BrightnessPanel - Popup panel with brightness and night light controls
 * Shows: Brightness slider, night light toggle section
 */
PanelPopup {
  id: root

  property real panelWidth: 260
  panelContentItem: panelContent

  // Brightness state from BrightnessService
  readonly property real brightness: BrightnessService.brightness
  readonly property int brightnessPercent: Math.round(brightness * 100)

  // Panel background
  Rectangle {
    id: panelContent
    width: root.panelWidth
    height: contentColumn.implicitHeight + Style.marginL * 2
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Style.borderS

    // Shadow effect
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      z: -1
      radius: parent.radius + 2
      color: Qt.alpha(Color.mShadow, 0.3)
    }

    ColumnLayout {
      id: contentColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header with brightness icon and percentage
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: Color.mSecondary  // Yellow for brightness

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          Text {
            text: BrightnessService.getIcon()
            color: Color.mOnSecondary
            font.family: Style.fontFamily
            font.pixelSize: 22
          }

          Column {
            Layout.fillWidth: true
            spacing: -2

            Text {
              text: root.brightnessPercent + "%"
              color: Color.mOnSecondary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
              font.weight: Style.fontWeightBold
            }

            Text {
              text: "Brightness"
              color: Qt.alpha(Color.mOnSecondary, 0.7)
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
            }
          }
        }
      }

      // Brightness slider card
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Low brightness icon
          Text {
            text: "󰃞"
            color: Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeL
          }

          // Slider track
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            // Track background
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              height: 6
              radius: 3
              color: Color.mOutline
            }

            // Track fill
            Rectangle {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width * root.brightness
              height: 6
              radius: 3
              color: Color.mSecondary

              Behavior on width {
                NumberAnimation { duration: 50 }
              }
            }

            // Handle
            Rectangle {
              x: parent.width * root.brightness - width / 2
              anchors.verticalCenter: parent.verticalCenter
              width: 16
              height: 16
              radius: width / 2
              color: Color.mSecondary
              border.color: Color.mSurface
              border.width: 2

              Behavior on x {
                NumberAnimation { duration: 50 }
              }
            }

            // Mouse interaction
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onPressed: (mouse) => {
                updateBrightness(mouse.x);
              }

              onPositionChanged: (mouse) => {
                if (pressed) {
                  updateBrightness(mouse.x);
                }
              }

              function updateBrightness(mouseX) {
                var newBrightness = Math.max(0.01, Math.min(1, mouseX / width));
                BrightnessService.setBrightness(newBrightness);
              }
            }
          }

          // High brightness icon
          Text {
            text: "󰃠"
            color: Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeL
          }
        }
      }

      // Night light section
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: nightLightColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS
        visible: NightLightService.available

        ColumnLayout {
          id: nightLightColumn
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Night light header row
          RowLayout {
            Layout.fillWidth: true

            Text {
              text: NightLightService.getIcon()
              color: NightLightService.enabled ? Color.mOrange : Color.mOnSurfaceVariant
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeL
            }

            Text {
              text: "Night Light"
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
              font.weight: Style.fontWeightSemiBold
              Layout.fillWidth: true
            }

            // State chip
            PanelStatusChip {
              label: NightLightService.getStateLabel()
              backgroundColor: {
                if (!NightLightService.enabled) return Color.mOutline;
                if (NightLightService.forced) return Color.mOrange;
                return Color.mTertiary;
              }
              foregroundColor: {
                if (!NightLightService.enabled) return Color.mOnSurfaceVariant;
                return Color.mSurface;
              }
            }
          }

          // Mode buttons row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
              model: [
                { label: "Off", enabled: false, forced: false },
                { label: "Auto", enabled: true, forced: false },
                { label: "On", enabled: true, forced: true }
              ]

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: Style.radiusS
                color: {
                  var isActive = (NightLightService.enabled === modelData.enabled && 
                                  NightLightService.forced === modelData.forced);
                  if (isActive) return Color.mPrimary;
                  if (modeMouseArea.containsMouse) return Qt.alpha(Color.mPrimary, 0.2);
                  return "transparent";
                }
                border.color: Color.mOutline
                border.width: Style.borderS

                Text {
                  anchors.centerIn: parent
                  text: modelData.label
                  color: {
                    var isActive = (NightLightService.enabled === modelData.enabled && 
                                    NightLightService.forced === modelData.forced);
                    return isActive ? Color.mOnPrimary : Color.mOnSurface;
                  }
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontSizeS
                  font.weight: Style.fontWeightMedium
                }

                MouseArea {
                  id: modeMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    NightLightService.enabled = modelData.enabled;
                    NightLightService.forced = modelData.forced;
                    NightLightService.apply();
                  }
                }
              }
            }
          }
        }
      }
    }

    // Animation
    scale: root.visible ? 1.0 : 0.95
    opacity: root.visible ? 1.0 : 0.0
    transformOrigin: Item.Top

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
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
