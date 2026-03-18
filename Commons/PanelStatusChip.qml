import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property color backgroundColor: Color.mOutline
  property color foregroundColor: Color.mOnSurfaceVariant
  property int horizontalPadding: Style.marginS * 2
  property int chipHeight: 22

  implicitWidth: chipText.implicitWidth + horizontalPadding
  implicitHeight: chipHeight
  radius: chipHeight / 2
  color: backgroundColor

  Text {
    id: chipText
    anchors.centerIn: parent
    text: root.label
    color: root.foregroundColor
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeXS
    font.weight: Style.fontWeightBold
  }
}
