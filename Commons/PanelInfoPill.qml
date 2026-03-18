import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""

  implicitHeight: 26
  radius: Style.radiusS
  color: Qt.alpha(Color.mSurface, 0.35)
  border.color: Color.mOutline
  border.width: Style.borderS

  Text {
    anchors.centerIn: parent
    text: root.label
    color: Color.mOnSurfaceVariant
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeXS
  }
}
