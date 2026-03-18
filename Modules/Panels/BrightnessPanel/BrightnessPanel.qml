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
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight

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
      SliderControl {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        value: root.brightness
        minValue: 0.01
        accentColor: Color.mSecondary
        iconColor: Color.mOnSurfaceVariant
        leftIcon: "󰃞"
        rightIcon: "󰃠"
        onValueChangeRequested: function(newValue) {
          BrightnessService.setBrightness(newValue);
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

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
