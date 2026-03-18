import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property color backgroundColor: Qt.alpha(Color.mSurface, 0.35)
  property color foregroundColor: Color.mOnSurfaceVariant
  property bool hoverable: false

  readonly property bool isHovered: hoverTracker.containsMouse && hoverable

  implicitHeight: 26
  radius: Style.radiusS
  color: isHovered ? Qt.alpha(backgroundColor, 0.82) : backgroundColor
  border.color: Color.mOutline
  border.width: Style.borderS

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Style.easingStandard
    }
  }

  Behavior on foregroundColor {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Style.easingStandard
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.label
    color: root.foregroundColor
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeXS
  }

  MouseArea {
    id: hoverTracker
    anchors.fill: parent
    hoverEnabled: root.hoverable
    acceptedButtons: Qt.NoButton
    enabled: root.hoverable
    cursorShape: Qt.ArrowCursor
  }
}
