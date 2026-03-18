import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

/*
 * Niruv Wallpaper Widget - Click to set random wallpaper via swaybg
 */
Item {
  id: root

  property ShellScreen screen: null

  // Wallpaper directory
  readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

  // Auto-change interval in seconds. Set to 0 to disable.
  property int autoChangeInterval: 600

  // Dimensions
  implicitWidth: iconText.implicitWidth
  implicitHeight: Style.barHeight

  // Background pill (only visible on hover)
  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    width: iconText.implicitWidth + Style.marginS * 2
    height: 18
    radius: height / 2
    color: mouseArea.containsMouse ? Color.mBlue : Color.transparent

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
  }

  // Wallpaper icon
  Text {
    id: iconText
    anchors.centerIn: parent
    text: "󰟾"  // Nerd Font wallpaper/image icon
    color: mouseArea.containsMouse ? Color.mOnPrimary : Color.mOnSurface
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeL

    Behavior on color {
      ColorAnimation { duration: Style.animationFast }
    }
  }

  // Process to set random wallpaper
  Process {
    id: wallpaperProcess
    command: [Settings.oNIgiRIBinDir + "niri-random-wallpaper"]
  }

  // Auto-rotation timer
  Timer {
    id: autoTimer
    interval: autoChangeInterval * 1000
    running: autoChangeInterval > 0
    repeat: true
    triggeredOnStart: false
    onTriggered: wallpaperProcess.running = true
  }

  // Mouse interaction
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      wallpaperProcess.running = true;
    }
  }
}
