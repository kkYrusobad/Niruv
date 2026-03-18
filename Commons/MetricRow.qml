import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root

  property string icon: ""
  property string label: ""
  property string value: ""
  property color iconColor: Color.mPrimary
  property color labelColor: Color.mOnSurfaceVariant
  property color valueColor: Color.mOnSurface
  property int iconSize: Style.fontSizeM
  property int textSize: Style.fontSizeS

  Layout.fillWidth: true
  spacing: Style.marginS

  Text {
    text: root.icon
    color: root.iconColor
    font.family: Style.fontFamily
    font.pixelSize: root.iconSize
  }

  Text {
    text: root.label
    color: root.labelColor
    font.family: Style.fontFamily
    font.pixelSize: root.textSize
    Layout.fillWidth: true
  }

  Text {
    text: root.value
    color: root.valueColor
    font.family: Style.fontFamily
    font.pixelSize: root.textSize
    font.weight: Style.fontWeightMedium
    horizontalAlignment: Text.AlignRight
  }
}
