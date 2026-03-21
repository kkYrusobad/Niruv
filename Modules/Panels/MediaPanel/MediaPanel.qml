import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons

/*
 * MediaPanel - Popup panel with full media controls
 * Shows: Album art, track info, playback controls, volume slider
 * Ultra-compact card layout.
 */
PanelPopup {
  id: root

  property real panelWidth: 300
  panelContentItem: panelContent

  // Current MPRIS player
  readonly property var currentPlayer: {
    if (!Mpris.players || !Mpris.players.values) return null;
    let players = Mpris.players.values;

    for (let i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing) return players[i];
    }
    for (let i = 0; i < players.length; i++) {
      if (players[i] && players[i].canControl) return players[i];
    }
    return null;
  }

  readonly property bool hasPlayer: currentPlayer !== null
  readonly property bool isPlaying: hasPlayer && currentPlayer.playbackState === MprisPlaybackState.Playing
  readonly property string trackTitle: hasPlayer ? (currentPlayer.trackTitle || "Unknown") : "Nothing Playing"
  readonly property string trackArtist: hasPlayer ? (currentPlayer.trackArtist || "Unknown Artist") : ""
  readonly property string albumArt: hasPlayer && currentPlayer.trackArtUrl ? currentPlayer.trackArtUrl : ""

  property real volumePercent: 100

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
      onRead: data => { root.volumePercent = parseInt(data.trim()) || 0; }
    }
  }

  // Set volume process
  Process {
    id: setVolumeProcess
    running: false
  }

  // Base background mimicking PanelSurface but manually managed for precise layout
  Rectangle {
    id: panelContent
    width: root.panelWidth
    height: layoutContainer.height
    radius: Style.radiusL
    color: Color.mSurfaceVariant
    
    // Ambient shadow
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      z: -2
      radius: parent.radius + 2
      color: Qt.alpha(Color.mShadow, 0.3)
    }

    // Hidden backing image for the blur effect
    Image {
      id: bgArt
      anchors.fill: parent
      source: root.albumArt
      fillMode: Image.PreserveAspectCrop
      visible: false // Hidden, only rendered through MultiEffect
    }

    // Blurs AND masks the image accurately to the rounded corners
    MultiEffect {
      anchors.fill: parent
      source: bgArt
      visible: root.albumArt !== ""
      
      autoPaddingEnabled: false // absolutely required to stop blur bleed!
      
      blurEnabled: true
      blurMax: 64
      blur: 1.0
      
      maskEnabled: true
      maskSource: ShaderEffectSource {
        sourceItem: Rectangle {
          width: panelContent.width
          height: panelContent.height
          radius: Style.radiusL
          color: "white"
        }
      }
    }

    // Dark overlay mask for contrast
    Rectangle {
      anchors.fill: parent
      radius: Style.radiusL
      color: Color.mSurface
      opacity: root.albumArt !== "" ? 0.75 : 0.95
      Behavior on opacity { NumberAnimation { duration: Style.animationFast } }
    }

    // Crisp Border
    Rectangle {
      anchors.fill: parent
      radius: Style.radiusL
      color: "transparent"
      border.color: Qt.alpha(Color.mOutline, 0.8)
      border.width: Style.borderS
    }

    // Precise, compact vertical layout
    Column {
      id: layoutContainer
      width: parent.width
      
      padding: Style.marginL
      spacing: Style.marginM // ~9px

      // Album Art
      Item {
        width: 100
        height: 100
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
          anchors.fill: parent
          radius: Style.radiusM
          color: Qt.alpha(Color.mOnSurface, 0.05)
          clip: true

          Image {
            anchors.fill: parent
            source: root.albumArt
            fillMode: Image.PreserveAspectCrop
            visible: root.albumArt !== ""
            smooth: true
            mipmap: true
          }

          Text {
            anchors.centerIn: parent
            text: "󰎆"
            color: Color.mOnSurfaceVariant
            font.family: Style.fontFamily
            font.pixelSize: 42
            visible: root.albumArt === ""
          }
        }
      }

      // Track Info 
      Column {
        width: parent.width - (Style.marginL * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.trackTitle
          color: Color.mOnSurface
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.trackArtist
          color: Color.mOnSurfaceVariant
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeS
          elide: Text.ElideRight
          visible: root.trackArtist !== ""
        }
      }

      // Playback Controls
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.marginL // ~13px

        // Previous button
        Rectangle {
          width: 34
          height: 34
          radius: 17
          color: prevMouseArea.containsMouse ? Qt.alpha(Color.mOnSurface, 0.1) : "transparent"
          opacity: root.hasPlayer && root.currentPlayer.canGoPrevious ? 1.0 : 0.4
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: "󰒮"
            color: Color.mOnSurface
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeL
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
          width: 46
          height: 46
          radius: 23
          color: Color.mPrimary
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: root.isPlaying ? "󰏤" : "󰐊"
            color: Color.mOnPrimary
            font.family: Style.fontFamily
            font.pixelSize: 22
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

          scale: playMouseArea.pressed ? 0.92 : 1.0
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationFaster
              easing.type: Style.easingEnter
            }
          }
        }

        // Next button
        Rectangle {
          width: 34
          height: 34
          radius: 17
          color: nextMouseArea.containsMouse ? Qt.alpha(Color.mOnSurface, 0.1) : "transparent"
          opacity: root.hasPlayer && root.currentPlayer.canGoNext ? 1.0 : 0.4
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: "󰒭"
            color: Color.mOnSurface
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSizeL
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

      // Seamless Volume Control
      Row {
        width: parent.width - (Style.marginL * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.marginM

        // Volume icon
        Text {
          id: volumeText
          text: root.volumePercent === 0 ? "󰖁" : (root.volumePercent < 50 ? "󰖀" : "󰕾")
          color: Color.mOnSurfaceVariant
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSizeL
          anchors.verticalCenter: parent.verticalCenter
        }

        // Volume slider trace
        Rectangle {
          width: parent.width - volumeText.width - Style.marginM
          height: 4
          radius: 2
          color: Qt.alpha(Color.mOnSurface, 0.2)
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            width: parent.width * (root.volumePercent / 100)
            height: parent.height
            radius: 2
            color: Color.mPrimary

            Behavior on width {
              NumberAnimation { duration: 100 }
            }
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -10 // Wider hit area
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton) {
                    updateVol(mouse);
                }
            }
            onClicked: mouse => {
                updateVol(mouse);
            }
            
            function updateVol(mouse) {
                let safeX = Math.max(0, Math.min(mouse.x, width));
                const newVol = Math.round((safeX / width) * 100);
                setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVol / 100).toFixed(2)];
                setVolumeProcess.running = true;
                root.volumePercent = newVol;
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
