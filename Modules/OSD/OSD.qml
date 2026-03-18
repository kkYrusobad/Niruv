import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.Commons
import qs.Services.Media
import qs.Services.Hardware

/*
 * Niruv OSD - On-Screen Display for volume, brightness, and media changes
 * Displays a floating overlay with progress bar and percentage
 */
Variants {
  id: osd

  // OSD Types
  enum Type {
    Volume,
    Brightness,
    Media
  }

  model: Quickshell.screens

  delegate: Loader {
    id: root

    required property ShellScreen modelData

    active: false

    // OSD State
    property int currentOSDType: -1  // OSD.Type enum value, -1 means none
    property bool startupComplete: false

    // Current values (computed properties)
    readonly property real currentVolume: AudioService.volume
    readonly property bool isMuted: AudioService.muted
    readonly property real currentBrightness: BrightnessService.brightness

    // Media properties
    readonly property var currentPlayer: {
      if (!Mpris.players || !Mpris.players.values) return null;
      let players = Mpris.players.values;
      for (let i = 0; i < players.length; i++) {
        if (players[i] && players[i].playbackState === MprisPlaybackState.Playing) {
          return players[i];
        }
      }
      for (let i = 0; i < players.length; i++) {
        if (players[i] && players[i].canControl) {
          return players[i];
        }
      }
      return null;
    }

    readonly property bool hasPlayer: currentPlayer !== null
    readonly property string trackTitle: hasPlayer ? (currentPlayer.trackTitle || "") : ""
    readonly property string trackArtist: hasPlayer ? (currentPlayer.trackArtist || "") : ""
    property string lastTrackTitle: ""

    // Helper Functions
    function getIcon() {
      switch (currentOSDType) {
      case OSD.Type.Volume:
        if (isMuted) return "󰝟";
        if (currentVolume < 0.01) return "󰝟";
        if (currentVolume <= 0.33) return "󰕿";
        if (currentVolume <= 0.66) return "󰖀";
        return "󰕾";
      case OSD.Type.Brightness:
        if (currentBrightness < 0.01) return "󰛩";
        if (currentBrightness <= 0.5) return "󰃞";
        return "󰃠";
      case OSD.Type.Media:
        return "󰎈";
      default:
        return "";
      }
    }

    function getCurrentValue() {
      switch (currentOSDType) {
      case OSD.Type.Volume:
        return isMuted ? 0 : currentVolume;
      case OSD.Type.Brightness:
        return currentBrightness;
      case OSD.Type.Media:
        return 1.0;
      default:
        return 0;
      }
    }

    function getDisplayPercentage() {
      if (currentOSDType === OSD.Type.Media) {
        return "";
      }
      const value = getCurrentValue();
      const pct = Math.round(value * 100);
      return pct + "%";
    }

    function getProgressColor() {
      if (currentOSDType === OSD.Type.Volume && isMuted) {
        return Color.mError;
      }
      return Color.mPrimary;
    }

    function getIconColor() {
      if (currentOSDType === OSD.Type.Volume && isMuted) {
        return Color.mError;
      }
      return Color.mOnSurface;
    }

    function getMediaText() {
      if (trackArtist && trackTitle) return trackArtist + " - " + trackTitle;
      if (trackTitle) return trackTitle;
      return "Unknown Track";
    }

    // OSD Display Control
    function showOSD(type) {
      if (!startupComplete) return;

      currentOSDType = type;

      if (!root.active) {
        root.active = true;
      }

      if (root.item) {
        root.item.showOSD();
      } else {
        Qt.callLater(() => {
          if (root.item) root.item.showOSD();
        });
      }
    }

    // Signal Connections - Volume
    Connections {
      target: AudioService

      function onVolumeUpdated() {
        root.showOSD(OSD.Type.Volume);
      }

      function onMutedUpdated() {
        root.showOSD(OSD.Type.Volume);
      }
    }

    // Signal Connections - Brightness
    Connections {
      target: BrightnessService

      function onBrightnessUpdated() {
        root.showOSD(OSD.Type.Brightness);
      }
    }

    // Track media changes
    onTrackTitleChanged: {
      if (startupComplete && trackTitle && trackTitle !== lastTrackTitle) {
        lastTrackTitle = trackTitle;
        showOSD(OSD.Type.Media);
      }
    }

    // Startup timer - enable OSD after 2 seconds to avoid initial noise
    Timer {
      id: startupTimer
      interval: 2000
      running: true
      onTriggered: {
        root.startupComplete = true;
        root.lastTrackTitle = root.trackTitle;
        Logger.d("OSD", "OSD startup complete");
      }
    }

    // Visual Component
    sourceComponent: PanelWindow {
      id: panel
      screen: modelData

      // Position: top-right corner
      anchors.top: true
      anchors.right: true

      // Margins to avoid bar
      margins.top: Style.barHeight + Style.marginM
      margins.right: Style.marginM

      // Dimensions
      readonly property int osdWidth: root.currentOSDType === OSD.Type.Media ? 320 : 280
      readonly property int osdHeight: 48
      readonly property int barThickness: 6

      implicitWidth: osdWidth
      implicitHeight: osdHeight
      color: "transparent"

      WlrLayershell.namespace: "niruv-osd-" + (screen?.name || "unknown")
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      Item {
        id: osdItem
        anchors.fill: parent
        visible: false
        opacity: 0
        scale: 0.9

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Style.easingStandard
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Style.easingEnter
          }
        }

        SequentialAnimation {
          id: lifecycleAnimation
          running: false

          PauseAnimation {
            duration: 2000
          }

          ParallelAnimation {
            NumberAnimation {
              target: osdItem
              property: "opacity"
              to: 0.0
              duration: Style.animationFast
              easing.type: Style.easingExit
            }

            NumberAnimation {
              target: osdItem
              property: "scale"
              to: 0.94
              duration: Style.animationFast
              easing.type: Style.easingExit
            }
          }

          ScriptAction {
            script: {
              osdItem.visible = false;
              root.currentOSDType = -1;
              root.active = false;
            }
          }
        }

        // Background
        Rectangle {
          id: background
          anchors.fill: parent
          anchors.margins: Style.marginS
          radius: Style.radiusM
          color: Color.mSurface
          border.color: Color.mOutline
          border.width: Style.borderS

          // Shadow effect
          Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            radius: parent.radius + 2
            color: Qt.alpha(Color.mShadow, osdItem.opacity * 0.3)
            visible: osdItem.visible
          }

          // Content
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.marginL
            anchors.rightMargin: Style.marginL
            spacing: Style.marginM

            // Icon
            Text {
              id: iconText
              text: root.getIcon()
              color: root.getIconColor()
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
              Layout.alignment: Qt.AlignVCenter

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                  easing.type: Style.easingStandard
                }
              }
            }

            // Progress Bar (for Volume/Brightness)
            Rectangle {
              visible: root.currentOSDType !== OSD.Type.Media
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              height: panel.barThickness
              radius: panel.barThickness / 2
              color: Color.mSurfaceVariant

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1.0, root.getCurrentValue())
                radius: parent.radius
                color: root.getProgressColor()

                Behavior on width {
                  NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Style.easingEnter
                  }
                }

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationFast
                    easing.type: Style.easingStandard
                  }
                }
              }
            }

            // Percentage Text (for Volume/Brightness)
            Text {
              visible: root.currentOSDType !== OSD.Type.Media
              text: root.getDisplayPercentage()
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightMedium
              Layout.alignment: Qt.AlignVCenter
              Layout.preferredWidth: 40
              horizontalAlignment: Text.AlignRight
            }

            // Media Text (for Media OSD)
            Text {
              visible: root.currentOSDType === OSD.Type.Media
              text: root.getMediaText()
              color: Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightMedium
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }

        function show() {
          lifecycleAnimation.stop();
          osdItem.visible = true;

          Qt.callLater(() => {
            osdItem.opacity = 1;
            osdItem.scale = 1.0;
          });

          lifecycleAnimation.start();
        }

        function hide() {
          lifecycleAnimation.stop();
          osdItem.opacity = 0;
          osdItem.scale = 0.94;

          Qt.callLater(() => {
            osdItem.visible = false;
            root.currentOSDType = -1;
            root.active = false;
          });
        }
      }

      function showOSD() {
        osdItem.show();
      }
    }
  }
}
