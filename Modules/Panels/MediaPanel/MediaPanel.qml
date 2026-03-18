import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons

/*
 * MediaPanel - Popup panel with full media controls
 * Shows: Album art, track info, playback controls, volume slider
 */
PanelPopup {
  id: root

  property real panelWidth: 320
  panelContentItem: panelContent

  // Current MPRIS player
  readonly property var currentPlayer: {
    if (!Mpris.players || !Mpris.players.values) return null;
    let players = Mpris.players.values;

    // First, find a playing player
    for (let i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing) {
        return players[i];
      }
    }
    // Fallback to first controllable player
    for (let i = 0; i < players.length; i++) {
      if (players[i] && players[i].canControl) {
        return players[i];
      }
    }
    return null;
  }

  readonly property bool hasPlayer: currentPlayer !== null
  readonly property bool isPlaying: hasPlayer && currentPlayer.playbackState === MprisPlaybackState.Playing
  readonly property string trackTitle: hasPlayer ? (currentPlayer.trackTitle || "Unknown") : "Nothing Playing"
  readonly property string trackArtist: hasPlayer ? (currentPlayer.trackArtist || "Unknown Artist") : ""
  readonly property string albumArt: hasPlayer && currentPlayer.trackArtUrl ? currentPlayer.trackArtUrl : ""

  // Volume state
  property real volumePercent: 100

  // Volume polling
  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: volumeProcess.running = true
  }

  Process {
    id: volumeProcess
    command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}'"]
    stdout: SplitParser {
      onRead: data => {
        root.volumePercent = parseInt(data.trim()) || 0;
      }
    }
  }

  // Panel background
  PanelSurface {
    id: panelContent
    width: root.panelWidth
    height: implicitHeight
    clip: true

    // Album art background (blurred effect via scaling)
    Loader {
      id: bgAlbumArtLoader
      anchors.fill: parent
      active: root.visible && root.albumArt !== ""

      sourceComponent: Component {
        Image {
          anchors.fill: parent
          anchors.margins: -20  // Extend beyond borders for blur effect
          source: root.albumArt
          fillMode: Image.PreserveAspectCrop
          opacity: 1.0

          // Scaling down and up creates soft blur effect
          sourceSize.width: 100
          sourceSize.height: 100
          smooth: true
          mipmap: true
        }
      }
    }

    // Semi-transparent overlay for readability
    Rectangle {
      anchors.fill: parent
      color: Color.mSurface
      opacity: bgAlbumArtLoader.active ? 0.65 : 1.0
      
      Behavior on opacity {
        NumberAnimation { duration: Style.animationNormal }
      }
    }

    ColumnLayout {
      id: contentColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Album art and track info header
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        radius: Style.radiusM
        color: Color.mPrimary
        clip: true

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          // Album art
          Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: Style.radiusS
            color: Qt.alpha(Color.mOnPrimary, 0.2)
            clip: true

            Image {
              anchors.fill: parent
              source: root.albumArt
              fillMode: Image.PreserveAspectCrop
              visible: root.albumArt !== ""
            }

            Text {
              anchors.centerIn: parent
              text: ""
              color: Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: 24
              visible: root.albumArt === ""
            }
          }

          // Track info
          Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
              width: parent.width
              text: root.trackTitle
              color: Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.trackArtist
              color: Qt.alpha(Color.mOnPrimary, 0.8)
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeS
              elide: Text.ElideRight
              visible: root.trackArtist !== ""
            }
          }
        }
      }

      // Playback controls
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.centerIn: parent
          spacing: Style.marginL

          // Previous button
          Rectangle {
            width: 40
            height: 40
            radius: width / 2
            color: prevMouseArea.containsMouse ? Color.mPrimary : Color.transparent
            opacity: root.hasPlayer && root.currentPlayer.canGoPrevious ? 1.0 : 0.4

            Text {
              anchors.centerIn: parent
              text: "󰒮"
              color: prevMouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
            }

            MouseArea {
              id: prevMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.hasPlayer && root.currentPlayer.canGoPrevious
              onClicked: root.currentPlayer.previous()
            }
          }

          // Play/Pause button
          Rectangle {
            width: 50
            height: 50
            radius: width / 2
            color: Color.mPrimary

            Text {
              anchors.centerIn: parent
              text: root.isPlaying ? "󰏤" : "󰐊"
              color: Color.mOnPrimary
              font.family: Style.fontFamily
              font.pixelSize: 24
            }

            MouseArea {
              id: playMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.hasPlayer
              onClicked: {
                if (root.isPlaying) {
                  root.currentPlayer.pause();
                } else {
                  root.currentPlayer.play();
                }
              }
            }

            scale: playMouseArea.pressed ? 0.95 : 1.0
            Behavior on scale {
              NumberAnimation {
                duration: Style.animationFaster
                easing.type: Style.easingEnter
              }
            }
          }

          // Next button
          Rectangle {
            width: 40
            height: 40
            radius: width / 2
            color: nextMouseArea.containsMouse ? Color.mPrimary : Color.transparent
            opacity: root.hasPlayer && root.currentPlayer.canGoNext ? 1.0 : 0.4

            Text {
              anchors.centerIn: parent
              text: "󰒭"
              color: nextMouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSizeXL
            }

            MouseArea {
              id: nextMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.hasPlayer && root.currentPlayer.canGoNext
              onClicked: root.currentPlayer.next()
            }
          }
        }
      }

      // Volume control
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          // Volume icon
          Text {
            text: root.volumePercent === 0 ? "󰖁" : (root.volumePercent < 50 ? "󰖀" : "󰕾")
            color: Color.mPrimary
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeXL
          }

          // Volume slider background
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Qt.alpha(Color.mOnSurface, 0.2)

            Rectangle {
              width: parent.width * (root.volumePercent / 100)
              height: parent.height
              radius: 4
              color: Color.mPrimary

              Behavior on width {
                NumberAnimation { duration: 100 }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: mouse => {
                const newVol = Math.round((mouse.x / width) * 100);
                setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVol / 100).toFixed(2)];
                setVolumeProcess.running = true;
                root.volumePercent = newVol;
              }
            }
          }

          // Volume percentage
          Text {
            text: root.volumePercent + "%"
            color: Color.mOnSurface
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeS
            font.weight: Style.fontWeightMedium
            Layout.preferredWidth: 35
            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }

  // Set volume process
  Process {
    id: setVolumeProcess
    running: false
  }

  // Close on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.close()
  }
}
