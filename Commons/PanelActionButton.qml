import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property color accentColor: Color.mPrimary
  property color baseColor: Color.mSurfaceVariant
  property color textColor: Color.mOnSurface
  property bool compact: false

  signal clicked

  implicitHeight: compact ? 32 : 36
  radius: Style.radiusS
  border.color: Color.mOutline
  border.width: Style.borderS
  color: buttonMouse.containsMouse ? Qt.alpha(accentColor, 0.2) : baseColor
  scale: buttonMouse.pressed ? 0.985 : 1.0

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Style.easingStandard
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: Style.animationFaster
      easing.type: Style.easingEnter
    }
  }

  RowLayout {
    anchors.centerIn: parent
    spacing: Style.marginS

    Text {
      text: root.icon
      color: root.accentColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeL
    }

    Text {
      text: root.label
      color: root.textColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSizeS
      font.weight: Style.fontWeightMedium
    }
  }

  MouseArea {
    id: buttonMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
