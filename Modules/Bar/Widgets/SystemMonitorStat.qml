import QtQuick
import qs.Commons

Row {
  id: root

  property string icon: ""
  property string value: ""
  property bool hovered: false
  property bool danger: false
  property color normalIconColor: Color.mBlue

  spacing: 2
  anchors.verticalCenter: parent.verticalCenter

  Text {
    text: root.icon
    color: root.hovered ? Color.mOnPrimary : (root.danger ? Color.mError : root.normalIconColor)
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeL
    anchors.verticalCenter: parent.verticalCenter

    Behavior on color {
      ColorAnimation { duration: Style.animationFast }
    }
  }

  Text {
    text: root.value
    color: root.hovered ? Color.mOnPrimary : Color.mOnSurface
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSizeS
    font.weight: Style.fontWeightMedium
    anchors.verticalCenter: parent.verticalCenter

    Behavior on color {
      ColorAnimation { duration: Style.animationFast }
    }
  }
}
