import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property color backgroundColor: Color.mOutline
  property color foregroundColor: Color.mOnSurfaceVariant
  property int horizontalPadding: Style.marginS * 2
  property int chipHeight: 22
  property bool hoverable: false

  readonly property bool isHovered: hoverTracker.containsMouse && hoverable

  implicitWidth: chipText.implicitWidth + horizontalPadding
  implicitHeight: chipHeight
  radius: chipHeight / 2
  color: isHovered ? Qt.lighter(backgroundColor, 1.08) : backgroundColor

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
    id: chipText
    anchors.centerIn: parent
    text: root.label
    color: root.foregroundColor
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeXS
    font.weight: Style.fontWeightBold
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
